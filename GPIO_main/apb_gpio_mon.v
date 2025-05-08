//------------------------------------------------------------------------------
// File: tb_gpio_apb_monitor.v
// Description:
//   Verilog monitor module for tb_gpio_apb_w1c testbench.
//   Observes APB transactions, strap sampling, and interrupt events.
//------------------------------------------------------------------------------
module tb_gpio_apb_monitor (
    input          PCLK,
    input          PRESETn,
    input          PSEL,
    input          PENABLE,
    input          PWRITE,
    input   [5:0]  PADDR,
    input  [31:0]  PWDATA,
    input  [31:0]  PRDATA,
    input          PREADY,
    input          PSLVERR,
    input  [31:0]  gpio_in,
    input          strap_en,
    input          strap_sample_valid,
    input  [31:0]  strap_sample_data,
    input          irq
);

  // Track previous IRQ state for edge detection
  reg prev_irq;

  initial begin
    prev_irq = 0;
    $display("Time(ns) | Event");
  end

  // APB bus transaction monitor
  always @(posedge PCLK) begin
    if (PSEL && PENABLE) begin
      if (PWRITE) begin
        $display("%0t | APB WRITE Addr=0x%02h Data=0x%08h Ready=%b Err=%b", 
                 $time, PADDR, PWDATA, PREADY, PSLVERR);
      end else begin
        $display("%0t | APB READ  Addr=0x%02h Data=0x%08h Ready=%b Err=%b", 
                 $time, PADDR, PRDATA, PREADY, PSLVERR);
      end
    end
  end

  // Strap sampling monitor
  always @(posedge PCLK) begin
    if (strap_en) begin
      $display("%0t | Strap EN asserted", $time);
    end
    if (strap_sample_valid) begin
      $display("%0t | Strap SAMPLE Data=0x%08h", $time, strap_sample_data);
    end
  end

  // Interrupt edge monitor
  always @(posedge PCLK) begin
    if (irq && !prev_irq) begin
      $display("%0t | IRQ ASSERTED", $time);
    end else if (!irq && prev_irq) begin
      $display("%0t | IRQ CLEARED", $time);
    end
    prev_irq <= irq;
  end

endmodule
