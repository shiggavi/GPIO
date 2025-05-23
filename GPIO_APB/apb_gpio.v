`timescale 1ns/1ps

//------------------------------------------------------------------------------
// Two-stage synchronizer primitive
// Ensures asynchronous inputs are safely synchronized to clk_i domain
//------------------------------------------------------------------------------
module prim_flop_2sync #(
    parameter integer Width = 1       // Number of bits to synchronize
) (
    input               clk_i,       // Clock input
    input               rst_ni,      // Active-low reset
    input  [Width-1:0]  d_i,         // Asynchronous data in
    output reg [Width-1:0] q_o       // Synchronized data out
);
  // Internal flop stage
  reg [Width-1:0] ff0;

  // On reset, clear both flops; otherwise shift data through two stages
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ff0 <= {Width{1'b0}};         // Clear first-stage flop
      q_o <= {Width{1'b0}};         // Clear output flop
    end else begin
      ff0 <= d_i;                   // Stage 1 captures async input
      q_o <= ff0;                   // Stage 2 outputs previous stage
    end
  end
endmodule


//------------------------------------------------------------------------------
// Filter-counter primitive
// Debounces input by requiring stable level for thresh_i cycles
//------------------------------------------------------------------------------
module prim_filter_ctr #(
    parameter bit     AsyncOn   = 1'b1, // Enable two-stage sync on filter_i
    parameter integer CntWidth = 2      // Counter width for debounce
) (
    input                  clk_i,       // Clock input
    input                  rst_ni,      // Active-low reset
    input                  enable_i,    // Enable filtering per pin
    input                  filter_i,    // Raw input bit
    input  [CntWidth-1:0]  thresh_i,    // Threshold count
    output                 filter_o     // Debounced output bit
);
  // Synchronized sample of filter_i
  wire filt_s;
  // Counter tracking stable cycles
  reg  [CntWidth-1:0] diff_q;
  // Registered previous stable sample
  reg                 filt_q;
  // Final stored output after threshold reached
  reg                 stored_q;
  // Next counter value
  wire [CntWidth-1:0] diff_d;

  // Optional two-stage synchronizer for filter_i
  generate
    if (AsyncOn) begin
      prim_flop_2sync #(.Width(1)) sync0 (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .d_i    (filter_i),
        .q_o    (filt_s)
      );
    end else begin
      assign filt_s = filter_i;        // Bypass sync if disabled
    end
  endgenerate

  // Register previous sample
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)      filt_q <= 1'b0; // Clear on reset
    else              filt_q <= filt_s;
  end

  // Compute next counter: reset on change, cap at threshold, else increment
  assign diff_d = (filt_s != filt_q) ? {CntWidth{1'b0}} :
                  (diff_q >= thresh_i)    ? thresh_i    :
                                            diff_q + 1;

  // Update counter
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)      diff_q <= {CntWidth{1'b0}}; // Clear on reset
    else              diff_q <= diff_d;
  end

  // Latch stable value once threshold reached
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)            stored_q <= 1'b0;     // Clear on reset
    else if (diff_d == thresh_i)
                            stored_q <= filt_s;   // Update when stable
  end

  // Output either debounced or raw based on enable
  assign filter_o = enable_i ? stored_q : filt_s;
endmodule


//------------------------------------------------------------------------------
// Implements 32-bit GPIO controller with filtering, interrupts, straps
//------------------------------------------------------------------------------
module gpio_apb #(
    // Base addresses for GPIO APB register map (offsets from peripheral base)
    parameter bit AsyncOn               = 1'b1,  // Enable two-stage synchronizer on inputs
    parameter ADDR_IN                   = 6'h00, // Read filtered GPIO inputs
    parameter ADDR_DIRECT_OUT           = 6'h04, // Write full 32-bit GPIO output register
    parameter ADDR_MASKED_OUT_LOWER     = 6'h08, // Masked write lower 16 bits of GPIO outputs
    parameter ADDR_MASKED_OUT_UPPER     = 6'h0C, // Masked write upper 16 bits of GPIO outputs
    parameter ADDR_DIR                  = 6'h10, // GPIO direction register (1=output, 0=input)
    parameter ADDR_IE                   = 6'h14, // Interrupt enable register (per-pin mask)
    parameter ADDR_EDGE                 = 6'h18, // Edge select register (1=rising, 0=falling)
    parameter ADDR_IFG                  = 6'h1C, // Interrupt flag register (sticky)
    parameter ADDR_STRAP_VALID          = 6'h20, // Strap valid flag register (clear/arm)
    parameter ADDR_STRAP_DATA           = 6'h24, // Latched strap data register
    parameter ADDR_FILT_EN              = 6'h28, // Filter enable register (per-pin mask)
    parameter ADDR_FILT_TH0             = 6'h2C, // Filter threshold for pins 0-7
    parameter ADDR_FILT_TH1             = 6'h30, // Filter threshold for pins 8-15
    parameter ADDR_FILT_TH2             = 6'h34, // Filter threshold for pins 16-23
    parameter ADDR_FILT_TH3             = 6'h38  // Filter threshold for pins 24-31
) (
    // APB bus interface
    input         PCLK,              // Bus clock
    input         PRESETn,           // Active-low bus reset
    input         stall,             // Stall signal for ready
    input         err,               // Slave error indicator
    input         PSEL,              // Peripheral select
    input         PENABLE,           // Access enable phase
    input         PWRITE,            // Read/Write flag
    input  [5:0]  PADDR,             // Register address
    input  [31:0] PWDATA,            // Write data bus
    output reg [31:0] PRDATA,        // Read data bus
    output reg        PREADY,        // Transfer ready
    output reg        PSLVERR,       // Transfer error

    // GPIO and strap interfaces
    input  [31:0] gpio_in,           // Raw GPIO inputs
    input         strap_en,          // One-shot strap capture
    output reg [31:0] gpio_out,      // GPIO outputs
    output reg [31:0] gpio_dir,      // GPIO direction mask
    output        irq,               // Global interrupt
    output reg    strap_sample_valid,// Strap valid flag
    output reg [31:0] strap_sample_data // Latched strap data
);

  // Internal state registers
  reg [31:0] r_in_d;                // Previous filtered inputs
  reg [31:0] r_out;                 // Output register
  reg [31:0] r_dir;                 // Direction register
  reg [31:0] r_ie;                  // Interrupt enable mask
  reg [31:0] r_edge;                // Edge selection
  reg [31:0] r_ifg;                 // Sticky flags
  reg [31:0] r_filt_en;             // Filter enable mask
  reg [127:0] r_filt_thresh;        // 4-bit thresholds ×32
  reg        strap_done;            // Strap capture done flag
  reg        ready_q;               // Internal ready pipeline

  // APB access strobes
  wire write_en = PSEL & PENABLE & PWRITE;
  wire read_en  = PSEL & PENABLE & ~PWRITE;

  // PREADY stretch logic
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) ready_q <= 1'b1;
    else          ready_q <= ~stall;
  end
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      PREADY  <= 1'b1;             // Default ready after reset
      PSLVERR <= 1'b0;             // No error after reset
    end else begin
      PREADY  <= ready_q;          // Stretch if stall asserted
      PSLVERR <= err;              // Propagate external error
    end
  end

  // Generate per-pin filter & synchronizer instances
  wire [31:0] gpio_in_filtered;
  genvar gi;
  generate
    for (gi = 0; gi < 32; gi = gi+1) begin : FILTER
      prim_filter_ctr #(
        .AsyncOn  (AsyncOn),
        .CntWidth (4)             // 4-bit threshold per pin
      ) u_filt (
        .clk_i     (PCLK),
        .rst_ni    (PRESETn),
        .enable_i  (r_filt_en[gi]),
        .filter_i  (gpio_in[gi]),
        .thresh_i  (r_filt_thresh[gi*4 +:4]),
        .filter_o  (gpio_in_filtered[gi])
      );
    end
  endgenerate

  // Capture previous filtered value for edge detection
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn)      r_in_d <= 32'd0;
    else               r_in_d <= gpio_in_filtered;
  end

  // Strap sampling: latch raw inputs once
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      strap_done         <= 1'b0;
      strap_sample_valid <= 1'b0;
      strap_sample_data  <= 32'd0;
    end else if (strap_en && !strap_done) begin
      strap_sample_valid <= 1'b1;  // Flag data valid
      strap_sample_data  <= gpio_in;
      strap_done         <= 1'b1;  // Prevent further latches
    end else if (write_en && PADDR == ADDR_STRAP_VALID) begin
      // Clear valid and re-arm on write
      strap_sample_valid <= strap_sample_valid & ~PWDATA[0];
      if (PWDATA[0]) strap_done <= 1'b0;
    end
  end

  // Interrupt-flag logic: detect edges & mask
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn)      r_ifg <= 32'd0;
    else if (write_en && PADDR == ADDR_IFG)
                       r_ifg <= r_ifg & ~PWDATA;   // Clear flags
    else               r_ifg <= (r_ifg |
                           (((~r_in_d & gpio_in_filtered) & r_edge)
                          | ((r_in_d & ~gpio_in_filtered) & ~r_edge)))
                         & r_ie;    // Latch & mask
  end

  // Control registers & threshold writes
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      r_ie          <= 32'd0;
      r_edge        <= 32'd0;
      r_filt_en     <= 32'd0;
      r_filt_thresh <= {32{4'd4}}; // Default mid-level
    end else if (write_en) begin
      case (PADDR)
        ADDR_IE:       r_ie          <= PWDATA;
        ADDR_EDGE:     r_edge        <= PWDATA;
        ADDR_FILT_EN:  r_filt_en     <= PWDATA;
        ADDR_FILT_TH0: r_filt_thresh[ 31:  0] <= PWDATA;
        ADDR_FILT_TH1: r_filt_thresh[ 63: 32] <= PWDATA;
        ADDR_FILT_TH2: r_filt_thresh[ 95: 64] <= PWDATA;
        ADDR_FILT_TH3: r_filt_thresh[127: 96] <= PWDATA;
      endcase
    end
  end

  // Data-output register writes (direct & masked)
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn)      r_out <= 32'd0;
    else if (write_en) begin
      case (PADDR)
        ADDR_DIRECT_OUT:       r_out       <= PWDATA;                       // Overwrite all
        ADDR_MASKED_OUT_LOWER: r_out[15:0] <= (PWDATA[31:16] & PWDATA[15:0])
                                           | (~PWDATA[31:16] & r_out[15:0]); // Masked lower
        ADDR_MASKED_OUT_UPPER: r_out[31:16]<= (PWDATA[31:16] & PWDATA[15:0])
                                           | (~PWDATA[31:16] & r_out[31:16]); // Masked upper
      endcase
    end
  end

  // Direction register write
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn)      r_dir <= 32'd0;
    else if (write_en && PADDR == ADDR_DIR)
                       r_dir <= PWDATA;
  end

  // Drive registered outputs
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      gpio_out <= 32'd0;
      gpio_dir <= 32'd0;
    end else begin
      gpio_out <= r_out;
      gpio_dir <= r_dir;
    end
  end

  // Generate global IRQ when any flagged & enabled
  assign irq = |(r_ie & r_ifg);

  // Readback multiplexer for APB reads
  always @(*) begin
    if (read_en) begin
      case (PADDR)
        ADDR_IN:               PRDATA = gpio_in_filtered;            // Filtered inputs
        ADDR_DIRECT_OUT:       PRDATA = r_out;
        ADDR_MASKED_OUT_LOWER,
        ADDR_MASKED_OUT_UPPER: PRDATA = r_out;
        ADDR_DIR:              PRDATA = r_dir;
        ADDR_IE:               PRDATA = r_ie;
        ADDR_EDGE:             PRDATA = r_edge;
        ADDR_IFG:              PRDATA = r_ifg;
        ADDR_STRAP_VALID:      PRDATA = {31'd0, strap_sample_valid};
        ADDR_STRAP_DATA:       PRDATA = strap_sample_data;
        ADDR_FILT_TH0:         PRDATA = r_filt_thresh[ 31:  0];
        ADDR_FILT_TH1:         PRDATA = r_filt_thresh[ 63: 32];
        ADDR_FILT_TH2:         PRDATA = r_filt_thresh[ 95: 64];
        ADDR_FILT_TH3:         PRDATA = r_filt_thresh[127: 96];
        default:               PRDATA = 32'd0;
      endcase
    end else begin
      PRDATA = 32'd0; // Default when not reading
    end
  end
endmodule


//------------------------------------------------------------------------------
// Top-level wrapper: adds 32-bit bidirectional physical_pin bus
//------------------------------------------------------------------------------
module gpio_apb_top (
    input         PCLK,               // Bus clock
    input         PRESETn,            // Bus reset
    input         stall,              // Bus stall
    input         err,                // Bus error in
    input         PSEL,               // Bus select
    input         PENABLE,            // Bus enable
    input         PWRITE,             // Bus write flag
    input  [5:0]  PADDR,              // Bus address
    input  [31:0] PWDATA,             // Bus write data
    output [31:0] PRDATA,             // Bus read data
    output        PREADY,             // Bus ready
    output        PSLVERR,            // Bus error out
    input         strap_en,           // Strap capture trigger
    output        strap_sample_valid, // Strap data valid
    output [31:0] strap_sample_data,  // Latched strap data
    output        irq,                // Interrupt out
    inout  [31:0] physical_pin        // Physical I/O pads
);

  // Internal nets connecting pad logic to core
  wire [31:0] gpio_in;
  wire [31:0] gpio_out;
  wire [31:0] gpio_dir;

  // Instantiate core controller
  gpio_apb u_gpio_apb (
    .PCLK               (PCLK),
    .PRESETn            (PRESETn),
    .stall              (stall),
    .err                (err),
    .PSEL               (PSEL),
    .PENABLE            (PENABLE),
    .PWRITE             (PWRITE),
    .PADDR              (PADDR),
    .PWDATA             (PWDATA),
    .PRDATA             (PRDATA),
    .PREADY             (PREADY),
    .PSLVERR            (PSLVERR),
    .gpio_in            (gpio_in),
    .strap_en           (strap_en),
    .gpio_out           (gpio_out),
    .gpio_dir           (gpio_dir),
    .irq                (irq),
    .strap_sample_valid (strap_sample_valid),
    .strap_sample_data  (strap_sample_data)
  );

  // Tri-state pad generation: drive or float based on gpio_dir
  genvar i;
  generate
    for (i = 0; i < 32; i = i + 1) begin : PADS
      assign physical_pin[i] = gpio_dir[i] ? gpio_out[i] : 1'bz;
      assign gpio_in[i]      = physical_pin[i];
    end
  endgenerate
endmodule

