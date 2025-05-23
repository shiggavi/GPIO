`timescale 1ns/1ps
module tb_gpio_apb_top;

  // Clock & reset
  reg  PCLK = 0;
  always #5 PCLK = ~PCLK;

  reg  PRESETn;

  // Control inputs
  reg  stall;
  reg  err_in;

  // APB interface signals
  reg         PSEL, PENABLE, PWRITE;
  reg  [5:0]  PADDR;
  reg  [31:0] PWDATA;
  wire [31:0] PRDATA;
  wire        PREADY;
  wire        PSLVERR;

  // Strap sampling
  reg         strap_en;
  wire        strap_sample_valid;
  wire [31:0] strap_sample_data;

  // Interrupt
  wire        irq;

  // Bidirectional pads
  wire [31:0] physical_pin;

  // Testbench-driving force for pad when dir=0
  reg  [31:0] pad_drv;

  // UUT: top wrapper
  gpio_apb_top uut (
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
    .strap_en           (strap_en),
    .strap_sample_valid (strap_sample_valid),
    .strap_sample_data  (strap_sample_data),
    .irq                (irq),
    .physical_pin       (physical_pin)
  );

  // pad-driving logic when OE=0
  initial pad_drv = 32'hzzzz_zzzz;
  genvar gi;
  generate
    for (gi = 0; gi < 32; gi = gi + 1) begin : DRV_LOOP
      assign physical_pin[gi] = (pad_drv[gi] !== 1'bz)
                                ? pad_drv[gi]
                                : 1'bz;
    end
  endgenerate

  // APB write task
  task apb_write(input [5:0] addr, input [31:0] data);
    @(posedge PCLK);
      PSEL    = 1; PWRITE = 1; PADDR = addr; PWDATA = data; PENABLE = 0;
    @(posedge PCLK);
      PENABLE = 1; wait (PREADY);
    @(posedge PCLK);
      PSEL    = 0; PENABLE = 0; PWRITE = 0;
  endtask

  // APB read task
  task apb_read(input [5:0] addr, output [31:0] data);
    @(posedge PCLK);
      PSEL    = 1; PWRITE = 0; PADDR = addr; PENABLE = 0;
    @(posedge PCLK);
      PENABLE = 1; wait (PREADY);
    @(posedge PCLK);
      data    = PRDATA;
      PSEL    = 0; PENABLE = 0;
  endtask

  // APB register offsets
  localparam
    ADDR_IN               = 6'h00,
    ADDR_DIRECT_OUT       = 6'h04,
    ADDR_MASKED_OUT_LOWER = 6'h08,
    ADDR_MASKED_OUT_UPPER = 6'h0C,
    ADDR_DIR              = 6'h10,
    ADDR_IE               = 6'h14,
    ADDR_EDGE             = 6'h18,
    ADDR_IFG              = 6'h1C,
    ADDR_STRAP_VALID      = 6'h20,
    ADDR_STRAP_DATA       = 6'h24,
    ADDR_FILT_TH0         = 6'h2C,
    ADDR_FILT_TH1         = 6'h30,
    ADDR_FILT_TH2         = 6'h34,
    ADDR_FILT_TH3         = 6'h38;

  reg [31:0] rd;
  integer    i;

  initial begin
    $dumpfile("tb_gpio_apb_top.vcd");
    $dumpvars(0, tb_gpio_apb_top);

    // reset
    PRESETn = 0; stall = 0; err_in = 0;
    PSEL = 0; PENABLE = 0; PWRITE = 0;
    strap_en = 0;
    pad_drv = 32'hzzzz_zzzz;
    #20;
    PRESETn = 1;
    #20;

    // 1) Wait-state test
    stall = 1;
    apb_write(ADDR_DIRECT_OUT, 32'hDEAD_BEEF);
    stall = 0;
    apb_read (ADDR_DIRECT_OUT, rd);
    if (rd === 32'hDEAD_BEEF) begin
      $display("%0t: PASS: wait-state write read back 0x%08h", $time, rd);
    end else begin
      $error("%0t: FAIL: wait-state write, got 0x%08h exp 0xDEADBEEF", $time, rd);
    end

    // 2) PSLVERR on error
    err_in = 1;
    apb_read (ADDR_DIRECT_OUT, rd);
    @(posedge PCLK);
    if (PSLVERR) begin
      $display("%0t: PASS: PSLVERR asserted when err=1", $time);
    end else begin
      $error("%0t: FAIL: PSLVERR not asserted", $time);
    end
    err_in = 0;

    // 3) Direct write/readback
    apb_write(ADDR_DIRECT_OUT, 32'hA5A5_A5A5);
    apb_read (ADDR_DIRECT_OUT, rd);
    if (rd === 32'hA5A5_A5A5) begin
      $display("%0t: PASS: direct write read back 0x%08h", $time, rd);
    end else begin
      $error("%0t: FAIL: direct write, got 0x%08h exp A5A5A5A5", $time, rd);
    end

    // 4) Masked lower
    apb_write(ADDR_MASKED_OUT_LOWER, {16'hFFFF,16'h1234});
    apb_read (ADDR_DIRECT_OUT, rd);
    if (rd[15:0] === 16'h1234) begin
      $display("%0t: PASS: masked lower = 0x%04h", $time, rd[15:0]);
    end else begin
      $error("%0t: FAIL: masked lower, got 0x%04h exp 1234", $time, rd[15:0]);
    end

    // 5) Masked upper
    apb_write(ADDR_DIRECT_OUT, 32'd0);
    apb_write(ADDR_MASKED_OUT_UPPER, {16'h0FF0,16'hABCD});
    apb_read (ADDR_DIRECT_OUT, rd);
    if (rd[31:16] === 16'h0BC0) begin
      $display("%0t: PASS: masked upper = 0x%04h", $time, rd[31:16]);
    end else begin
      $error("%0t: FAIL: masked upper, got 0x%04h exp 0x0BC0", $time, rd[31:16]);
    end

    // 6) Direction register
    apb_write(ADDR_DIR, 32'hFFFF_0000);
    apb_read (ADDR_DIR, rd);
    if (rd === 32'hFFFF_0000) begin
      $display("%0t: PASS: DIR = 0x%08h", $time, rd);
    end else begin
      $error("%0t: FAIL: DIR, got 0x%08h exp FFFF0000", $time, rd);
    end

    // 7) Tri-state drive test
    apb_write(ADDR_DIR,        32'hFFFF_FFFF);
    apb_write(ADDR_DIRECT_OUT, 32'hDEAD_C0DE);
    @(posedge PCLK); #1;
    if (physical_pin === 32'hDEAD_C0DE) begin
      $display("%0t: PASS: pad drive = 0x%08h", $time, physical_pin);
    end else begin
      $error("%0t: FAIL: pad drive, got 0x%08h exp DEADC0DE", $time, physical_pin);
    end

    // 8) Pad sampling
    apb_write(ADDR_DIR, 32'h0000_0000);
    pad_drv = 32'h1234_5678;
    repeat(2) @(posedge PCLK); #1;
    apb_read(ADDR_IN, rd);
    if (rd === 32'h1234_5678) begin
      $display("%0t: PASS: pad sample = 0x%08h", $time, rd);
    end else begin
      $error("%0t: FAIL: pad sample, got 0x%08h exp 12345678", $time, rd);
    end
    pad_drv = 32'hzzzz_zzzz;

    // 9) Interrupt test
    apb_write(ADDR_IE,   32'h0000_0001);
    apb_write(ADDR_EDGE, 32'h0000_0001);
    pad_drv = 32'h0000_0000;
    repeat(3) @(posedge PCLK);
    pad_drv = 32'h0000_0001;
    repeat(3) @(posedge PCLK); #1;
    apb_read(ADDR_IFG, rd);
    if (rd[0] && irq) begin
      $display("%0t: PASS: IRQ and IFG set", $time);
    end else begin
      $error("%0t: FAIL: IRQ test, IFG=%b irq=%b", $time, rd[0], irq);
    end
    apb_write(ADDR_IFG, 32'h0000_0001);
    @(posedge PCLK); #1;
    apb_read(ADDR_IFG, rd);
    if (rd[0] === 1'b0) begin
      $display("%0t: PASS: IRQ clear", $time);
    end else begin
      $error("%0t: FAIL: IRQ clear, IFG[0]=%b", $time, rd[0]);
    end

    // 10) Strap sampling
    pad_drv = 32'hCAFEBABE;
    @(posedge PCLK); strap_en = 1;
    @(posedge PCLK); strap_en = 0;
    @(posedge PCLK); #1;
    apb_read(ADDR_STRAP_VALID, rd);
    if (rd[0]) begin
      $display("%0t: PASS: strap valid set", $time);
    end else begin
      $error("%0t: FAIL: strap valid not set", $time);
    end
    apb_write(ADDR_STRAP_VALID, 32'h0000_0001);
    @(posedge PCLK); #1;
    apb_read(ADDR_STRAP_VALID, rd);
    if (!rd[0]) begin
      $display("%0t: PASS: strap valid cleared", $time);
    end else begin
      $error("%0t: FAIL: strap valid not cleared", $time);
    end
    apb_read(ADDR_STRAP_DATA, rd);
    if (rd === 32'hCAFEBABE) begin
      $display("%0t: PASS: strap data = 0x%08h", $time, rd);
    end else begin
      $error("%0t: FAIL: strap data, got 0x%08h exp CAFEBABE", $time, rd);
    end

    // 11) Threshold programming & readback
    for (i = 0; i < 4; i = i + 1) begin
      apb_write(ADDR_FILT_TH0 + i*4, {8{i[3:0]}});
      apb_read (ADDR_FILT_TH0 + i*4, rd);
      if (rd === {8{i[3:0]}}) begin
        $display("%0t: PASS: TH%0d = 0x%08h", $time, i, rd);
      end else begin
        $error("%0t: FAIL: TH%0d, got 0x%08h exp 0x%08h", $time, i, rd, {8{i[3:0]}});
      end
    end

    $display("%0t: ALL TESTS COMPLETE", $time);
    $finish;
  end

endmodule
