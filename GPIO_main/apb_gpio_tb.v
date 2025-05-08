`timescale 1ns/1ps
module tb_gpio_apb_w1c;

  // Clock & reset
  reg         PCLK = 0;
  reg         PRESETn;

  // Control inputs
  reg         stall;
  reg         err_in;

  // APB interface signals
  reg         PSEL, PENABLE, PWRITE;
  reg  [5:0]  PADDR;
  reg  [31:0] PWDATA;
  wire [31:0] PRDATA;
  wire        PREADY;
  wire        PSLVERR;

  // GPIO and strap
  reg  [31:0] gpio_in;
  reg         strap_en;
  wire [31:0] gpio_out;
  wire [31:0] gpio_dir;
  wire        irq;
  wire        strap_sample_valid;
  wire [31:0] strap_sample_data;

  // Instantiate DUT
  gpio_apb #(
    .AsyncOn(1)
  ) dut (
    .PCLK               (PCLK),
    .PRESETn            (PRESETn),
    .stall              (stall),
    .err                (err_in),
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

  // Clock generation
  always #5 PCLK = ~PCLK;

  // APB write task
  task apb_write(input [5:0] addr, input [31:0] data);
    @(posedge PCLK);
      PSEL    = 1; PWRITE = 1; PADDR = addr; PWDATA = data; PENABLE = 0;
    @(posedge PCLK);
      PENABLE = 1; wait(PREADY);
    @(posedge PCLK);
      PSEL    = 0; PENABLE = 0; PWRITE = 0;
  endtask

  // APB read task
  task apb_read(input [5:0] addr, output [31:0] data);
    @(posedge PCLK);
      PSEL    = 1; PWRITE = 0; PADDR = addr; PENABLE = 0;
    @(posedge PCLK);
      PENABLE = 1; wait(PREADY);
    @(posedge PCLK);
      data = PRDATA; PSEL = 0; PENABLE = 0;
  endtask

  // Address offsets
  localparam IN      = 6'h00,
             OUT     = 6'h04,
             MLOW    = 6'h08,
             MHIGH   = 6'h0C,
             DIR     = 6'h10,
             IE      = 6'h14,
             EDGE    = 6'h18,
             IFG     = 6'h1C,
             STRAPV  = 6'h20,
             STRAPD  = 6'h24,
             TH0     = 6'h2C,
             TH1     = 6'h30,
             TH2     = 6'h34,
             TH3     = 6'h38;

  reg [31:0] rd;
  integer i;

  initial begin
    $dumpfile("tb_gpio_w1c.vcd");
    $dumpvars(0, tb_gpio_apb_w1c);

    // Reset
    PRESETn = 0; stall = 0; err_in = 0;
    PSEL = 0; PENABLE = 0; PWRITE = 0;
    gpio_in = 0; strap_en = 0;
    #20; PRESETn = 1; #20;

  

        // 1) Wait-state test
    stall = 1;
    apb_write(OUT, 32'hDEAD_BEEF);
    stall = 0;
    apb_read (OUT, rd);
    $display("%0t: Wait-state write -> actual=0x%08h, expected=0xDEADBEEF", $time, rd);
    if (rd !== 32'hDEAD_BEEF) begin
      $display("ERROR: Wait-state mismatch at %0t", $time);
    end else begin
      $display("PASS: Wait-state match at %0t", $time);
    end

    // 2) Error test
    err_in = 1;
    apb_read (OUT, rd);
    @(posedge PCLK);
    $display("%0t: Error test -> PSLVERR=%b (expected=1)", $time, PSLVERR);
    if (!PSLVERR) begin
      $display("ERROR: PSLVERR not asserted at %0t", $time);
    end else begin
      $display("PASS: PSLVERR correctly asserted at %0t", $time);
    end
    err_in = 0;

    // 3) Direct write/readback
    apb_write(OUT, 32'hA5A5_A5A5);
    apb_read (OUT, rd);
    $display("%0t: Direct write -> actual=0x%08h, expected=0xA5A5A5A5", $time, rd);
    if (rd !== 32'hA5A5_A5A5) begin
      $display("ERROR: Direct write mismatch at %0t", $time);
    end else begin
      $display("PASS: Direct write match at %0t", $time);
    end

    // 4) Masked lower
    apb_write(MLOW, {16'hFFFF,16'h1234});
    apb_read (OUT, rd);
    $display("%0t: Masked lower -> actual=0x%04h, expected=0x1234", $time, rd[15:0]);
    if (rd[15:0] !== 16'h1234) begin
      $display("ERROR: Masked lower mismatch at %0t", $time);
    end else begin
      $display("PASS: Masked lower match at %0t", $time);
    end

    // 5) Masked upper
    apb_write(OUT, 32'd0);
    apb_write(MHIGH, {16'h0FF0,16'hABCD});
    apb_read (OUT, rd);
    $display("%0t: Masked upper -> actual=0x%04h, expected=0xABCD", $time, rd[31:16]);
    if (rd[31:16] !== 16'hABCD) begin
      $display("ERROR: Masked upper mismatch at %0t", $time);
    end else begin
      $display("PASS: Masked upper match at %0t", $time);
    end

    // 6) Direction register
    apb_write(DIR, 32'hFFFF_0000);
    apb_read (DIR, rd);
    $display("%0t: Direction -> actual=0x%08h, expected=0xFFFF0000", $time, rd);
    if (rd !== 32'hFFFF_0000) begin
      $display("ERROR: Direction mismatch at %0t", $time);
    end else begin
      $display("PASS: Direction match at %0t", $time);
    end

    // 7) Interrupt test
    apb_write(IE, 32'h1);
    apb_write(EDGE, 32'h1);
    gpio_in = 0; @(posedge PCLK);
    gpio_in = 1; @(posedge PCLK);
    apb_read (IFG, rd);
    $display("%0t: Interrupt -> IFG[0]=%b, irq=%b (expected=1,1)", $time, rd[0], irq);
    if (!rd[0] || !irq) begin
      $display("ERROR: Interrupt mismatch at %0t", $time);
    end else begin
      $display("PASS: Interrupt match at %0t", $time);
    end
    apb_write(IFG, 32'h1);
    apb_read (IFG, rd);
    $display("%0t: Interrupt clear -> IFG[0]=%b (expected=0)", $time, rd[0]);
    if (rd[0] !== 0) begin
      $display("ERROR: Interrupt clear failed at %0t", $time);
    end else begin
      $display("PASS: Interrupt clear at %0t", $time);
    end

    // 8) Strap sampling W1C
    gpio_in = 32'hCAFEBABE;
    strap_en = 1; @(posedge PCLK);
    strap_en = 0;
    apb_read (STRAPV, rd);
    $display("%0t: Strap valid -> actual=%b (expected=1)", $time, rd[0]);
    if (rd[0] !== 1) begin
      $display("ERROR: Strap valid mismatch at %0t", $time);
    end else begin
      $display("PASS: Strap valid at %0t", $time);
    end
    apb_write(STRAPV, 32'h1);
    apb_read (STRAPV, rd);
    $display("%0t: Strap valid clear -> actual=%b (expected=0)", $time, rd[0]);
    if (rd[0] !== 0) begin
      $display("ERROR: Strap valid clear at %0t", $time);
    end else begin
      $display("PASS: Strap valid clear at %0t", $time);
    end
    apb_read (STRAPD, rd);
    $display("%0t: Strap data -> actual=0x%08h, expected=0xCAFEBABE", $time, rd);
    if (rd !== 32'hCAFEBABE) begin
      $display("ERROR: Strap data mismatch at %0t", $time);
    end else begin
      $display("PASS: Strap data at %0t", $time);
    end

    // 9) Threshold programming & readback
    for (i = 0; i < 4; i = i + 1) begin
      PWDATA = {8{i[3:0]}};
      apb_write(TH0 + i*4, PWDATA);
      apb_read (TH0 + i*4, rd);
      $display("%0t: TH%0d -> actual=0x%08h, expected=0x%08h", $time, i, rd, PWDATA);
      if (rd !== PWDATA) begin
        $display("ERROR: TH%0d mismatch at %0t", i, $time);
      end else begin
        $display("PASS: TH%0d match at %0t", i, $time);
      end
    end
	
    // 0) Input register test
    // drive gpio_in and read back via ADDR_IN
    gpio_in = 32'h1234_ABCD;
    @(posedge PCLK);
    apb_read(IN, rd);
    $display("%0t: Input read -> actual=0x%08h, expected=0x1234ABCD", $time, rd);
    if (rd !== 32'h1234_ABCD) begin
      $display("ERROR: Input register mismatch at %0t", $time);
    end else begin
      $display("PASS: Input register match at %0t", $time);
    end
    $display("== TB COMPLETE ==");
    $finish;
  end
endmodule
