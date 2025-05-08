// Code your design here
//------------------------------------------------------------------------------
// Verilog-2005 / Verilator-friendly GPIO APB peripheral with 4-bit filter thresholds
//------------------------------------------------------------------------------
module gpio_apb #(
    parameter bit AsyncOn = 1'b1,
    parameter ADDR_IN               = 6'h00,
    parameter ADDR_DIRECT_OUT       = 6'h04,
    parameter ADDR_MASKED_OUT_LOWER = 6'h08,
    parameter ADDR_MASKED_OUT_UPPER = 6'h0C,
    parameter ADDR_DIR              = 6'h10,
    parameter ADDR_IE               = 6'h14,
    parameter ADDR_EDGE             = 6'h18,
    parameter ADDR_IFG              = 6'h1C,
    parameter ADDR_STRAP_VALID      = 6'h20,
    parameter ADDR_STRAP_DATA       = 6'h24,
    parameter ADDR_FILT_EN          = 6'h28,
    // four registers, each holds eight 4-bit thresholds
    parameter ADDR_FILT_TH0         = 6'h2C, // thresholds for pins 0-7
    parameter ADDR_FILT_TH1         = 6'h30, // pins 8-15
    parameter ADDR_FILT_TH2         = 6'h34, // pins 16-23
    parameter ADDR_FILT_TH3         = 6'h38  // pins 24-31
) (
    input         PCLK,
    input         PRESETn,
    input         stall,
    input         err,
    input         PSEL,
    input         PENABLE,
    input         PWRITE,
    input  [5:0]  PADDR,
    input  [31:0] PWDATA,
    output reg [31:0] PRDATA,
    output reg        PREADY,
    output reg        PSLVERR,
    input  [31:0] gpio_in,
    input         strap_en,
    output reg [31:0] gpio_out,
    output reg [31:0] gpio_dir,
    output        irq,
    output reg    strap_sample_valid,
    output reg [31:0] strap_sample_data
);

  // Internal regs
  reg [31:0] r_in_d, r_out, r_dir, r_ie, r_edge, r_ifg;
  reg [31:0] r_filt_en;
  reg [127:0] r_filt_thresh;  // 32 pins × 4 bits
  reg        strap_done;
  reg        ready_q;

  wire write_en = PSEL & PENABLE & PWRITE;
  wire read_en  = PSEL & PENABLE & ~PWRITE;

  // PREADY & PSLVERR
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) ready_q <= 1'b1;
    else          ready_q <= ~stall;
  end
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin PREADY <= 1'b1; PSLVERR <= 1'b0; end
    else           begin PREADY <= ready_q; PSLVERR <= err; end
  end

  // Synchronizer + filter
  wire [31:0] gpio_in_filtered;
  genvar gi;
  generate
    for (gi = 0; gi < 32; gi++) begin : FILTER
      prim_filter_ctr #(
        .AsyncOn  (AsyncOn),
        .CntWidth (4)
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

  // Capture previous filtered value
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) r_in_d <= 32'd0;
    else          r_in_d <= gpio_in_filtered;
  end

  // Strap sampling (one-shot)
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      strap_done         <= 1'b0;
      strap_sample_valid <= 1'b0;
      strap_sample_data  <= 32'd0;
    end else if (strap_en && !strap_done) begin
      strap_sample_valid <= 1'b1;
      strap_sample_data  <= gpio_in;
      strap_done         <= 1'b1;
    end else if (write_en && PADDR == ADDR_STRAP_VALID) begin
      strap_sample_valid <= strap_sample_valid & ~PWDATA[0];
      if (PWDATA[0]) strap_done <= 1'b0;
    end
  end

  // Interrupt flags
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) r_ifg <= 32'd0;
    else if (write_en && PADDR == ADDR_IFG) r_ifg <= r_ifg & ~PWDATA;
    else r_ifg <= (r_ifg | (((~r_in_d & gpio_in_filtered) & r_edge)
                           | ((r_in_d & ~gpio_in_filtered) & ~r_edge))) & r_ie;
  end

  // Control regs & thresholds write
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      r_ie          <= 32'd0;
      r_edge        <= 32'd0;
      r_filt_en     <= 32'd0;
      r_filt_thresh <= {32{4'd4}};
    end else if (write_en) begin
      case (PADDR)
        ADDR_IE:      r_ie      <= PWDATA;
        ADDR_EDGE:    r_edge    <= PWDATA;
        ADDR_FILT_EN: r_filt_en <= PWDATA;
        ADDR_FILT_TH0: r_filt_thresh[ 31:  0] <= PWDATA;
        ADDR_FILT_TH1: r_filt_thresh[ 63: 32] <= PWDATA;
        ADDR_FILT_TH2: r_filt_thresh[ 95: 64] <= PWDATA;
        ADDR_FILT_TH3: r_filt_thresh[127: 96] <= PWDATA;
      endcase
    end
  end

  // Output register writes
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) r_out <= 32'd0;
    else if (write_en) begin
      case (PADDR)
        ADDR_DIRECT_OUT:       r_out       <= PWDATA;
        ADDR_MASKED_OUT_LOWER: r_out[15:0] <= (PWDATA[31:16] & PWDATA[15:0])
                                           | (~PWDATA[31:16] & r_out[15:0]);
        ADDR_MASKED_OUT_UPPER: r_out[31:16]<= (PWDATA[31:16] & PWDATA[15:0])
                                           | (~PWDATA[31:16] & r_out[31:16]);
      endcase
    end
  end

  // Direction register
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) r_dir <= 32'd0;
    else if (write_en && PADDR == ADDR_DIR) r_dir <= PWDATA;
  end

  // Drive outputs
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      gpio_out <= 32'd0;
      gpio_dir <= 32'd0;
    end else begin
      gpio_out <= r_out;
      gpio_dir <= r_dir;
    end
  end

  assign irq = |(r_ie & r_ifg);

  // Readback
  always @(*) begin
    if (read_en) begin
      case (PADDR)
        ADDR_IN:               PRDATA = gpio_in_filtered;
        ADDR_DIRECT_OUT:       PRDATA = r_out;
        ADDR_MASKED_OUT_LOWER,
        ADDR_MASKED_OUT_UPPER: PRDATA = r_out;
        ADDR_DIR:              PRDATA = r_dir;
        ADDR_IE:               PRDATA = r_ie;
        ADDR_EDGE:             PRDATA = r_edge;
        ADDR_IFG:              PRDATA = r_ifg;
        ADDR_STRAP_VALID:      PRDATA = {31'd0, strap_sample_valid};
        ADDR_STRAP_DATA:       PRDATA = strap_sample_data;
        ADDR_FILT_TH0: PRDATA = r_filt_thresh[ 31:  0];
        ADDR_FILT_TH1: PRDATA = r_filt_thresh[ 63: 32];
        ADDR_FILT_TH2: PRDATA = r_filt_thresh[ 95: 64];
        ADDR_FILT_TH3: PRDATA = r_filt_thresh[127: 96];
        default:               PRDATA = 32'd0;
      endcase
    end else PRDATA = 32'd0;
  end
endmodule
// Two-stage synchronizer primitive
module prim_flop_2sync #(
    parameter integer Width = 1
) (
    input               clk_i,
    input               rst_ni,
    input  [Width-1:0]  d_i,
    output reg [Width-1:0] q_o
);
  reg [Width-1:0] ff0;
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin ff0 <= 0; q_o <= 0; end
    else begin ff0 <= d_i; q_o <= ff0; end
  end
endmodule

// Filter-counter primitive
module prim_filter_ctr #(
    parameter bit     AsyncOn   = 1'b1,
    parameter integer CntWidth = 2
) (
    input                  clk_i,
    input                  rst_ni,
    input                  enable_i,
    input                  filter_i,
    input  [CntWidth-1:0]  thresh_i,
    output                 filter_o
);
  wire filt_s;
  reg  [CntWidth-1:0] diff_q;
  reg                 filt_q, stored_q;
  wire [CntWidth-1:0] diff_d;

  generate if (AsyncOn) begin
    prim_flop_2sync #(.Width(1)) sync0 (
      .clk_i(clk_i), .rst_ni(rst_ni), .d_i(filter_i), .q_o(filt_s)
    );
  end else begin
    assign filt_s = filter_i;
  end endgenerate

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) filt_q <= 0; else filt_q <= filt_s;
  end

  assign diff_d = (filt_s != filt_q) ? {CntWidth{1'b0}} :
                 (diff_q >= thresh_i)    ? thresh_i    : diff_q + 1;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) diff_q <= 0; else diff_q <= diff_d;
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) stored_q <= 0;
    else if (diff_d == thresh_i) stored_q <= filt_s;
  end

  assign filter_o = enable_i ? stored_q : filt_s;
endmodule
