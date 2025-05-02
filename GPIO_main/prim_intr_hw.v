`timescale 1ns / 1ps

//------------------------------------------------------------------------------
// prim_intr_hw - Verilog-2005 & Verilator-Compatible Interrupt Generator
//------------------------------------------------------------------------------
// Description:
//   - Event or Status-based interrupt generation block used in peripherals.
//   - Compatible with reg2hw/hw2reg protocol defined by reggen.
//   - Drives intr_o output and intr_state CSR logic based on input events.
//   - Supports both "Event" (latched until cleared) and "Status" (level-triggered) modes.
//   - Optional output flopping controlled via FlopOutput.
//------------------------------------------------------------------------------
// This assumes the existence of three external controller registers, which
// interface with this module via the standard reggen reg2hw/hw2reg signals. The 3 registers are:
// - INTR_ENABLE : enables/masks the output of INTR_STATE as the intr_o signal
// - INTR_STATE  : the current state of the interrupt (may be RO or W1C depending on "IntrT")
// - INTR_TEST   : sw-access-only register which asserts the interrupt for testing purposes


  // As the wired interrupt signal intr_o is a level-triggered interrupt, the upstream consumer sw
  // has two options to make forward progress when this signal is asserted:
  // - Mask the interrupt, by setting INTR_ENABLE = 1'b0 or masking/enabling at an upstream
  //   consumer.
  // - Interact with the peripheral in some user-defined way that clears the signal.
  // To make this user-defined interaction ergonomic from a SW-perspective, we have defined
  // two common patterns for typical interrupt-triggering events, *Status* and *Event*.
  // - *Event* is useful for capturing a momentary assertion of the input signal.
  //   - INTR_STATE/intr_o is set to '1 upon the event occurring.
  //   - INTR_STATE/intr_o remain set until software writes-1-to-clear to INTR_STATE.
  // - *Status* captures a persistent conditional assertion that requires intervention to de-assert.
  //   - Until the root cause is alleviated, the interrupt output (while enabled) is continuously
  //     asserted.
  //   - INTR_STATE for *status* interrupts is RO (it simply presents the raw HW input signal).
  //   - If the root_cause is cleared, INTR_STATE/intr_o also clears automatically.
  // More details about the interrupt type distinctions can be found in the comportability docs.
module prim_intr_hw #(
  parameter Width = 1,                      // Number of interrupt lines
  parameter FlopOutput = 1'b1,              // Flop the intr_o output if 1
  parameter IntrIsEvent = 1'b1;           // Type: "Event" or "Status"
)(
  input                     clk_i,          // Clock
  input                     rst_ni,         // Asynchronous reset, active low

  // Hardware event signal for each interrupt
  input      [Width-1:0]    event_intr_i,

  // CSR interface signals from register bank
  input      [Width-1:0]    reg2hw_intr_enable_q_i, // Enable bit from INTR_ENABLE
  input      [Width-1:0]    reg2hw_intr_test_q_i,   // Test value from INTR_TEST
  input                     reg2hw_intr_test_qe_i,  // Write enable for INTR_TEST
  input      [Width-1:0]    reg2hw_intr_state_q_i,  // Current state of INTR_STATE

  // Output signals to register bank
  output                    hw2reg_intr_state_de_o, // Write enable for INTR_STATE
  output     [Width-1:0]    hw2reg_intr_state_d_o,  // New value for INTR_STATE

  // Output interrupt signal to the top level or NVIC
  output     [Width-1:0]   intr_o
);

  // Internal signal: gate test value when write enable is high
  wire [Width-1:0] test_valid = {Width{reg2hw_intr_test_qe_i}} & reg2hw_intr_test_q_i;

  // Combined event input (real hardware + test triggers)
  wire [Width-1:0] combined_event;

  // Latched interrupt status
  wire  [Width-1:0] status;

  generate
    if (IntrIsEvent) begin: g_event_type
      // In Event type: latch new interrupts until cleared by SW
      assign combined_event = test_valid | event_intr_i; // Trigger from either test or real event
      assign hw2reg_intr_state_de_o = |combined_event;   // Signal write to INTR_STATE if any bit is set
      assign hw2reg_intr_state_d_o  = combined_event | reg2hw_intr_state_q_i; // OR with previous state (sticky)

      assign status = reg2hw_intr_state_q_i; // Drive status from latched CSR value

    end else begin: g_status_type
      // In Status type: forward raw HW status or test result
      reg [Width-1:0] test_q;

      // Store INTR_TEST value
      always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
          test_q <= {Width{1'b0}};
        else if (reg2hw_intr_test_qe_i)
          test_q <= reg2hw_intr_test_q_i;
      end

      assign hw2reg_intr_state_de_o = 1'b1;                   // Always drive back to INTR_STATE
      assign hw2reg_intr_state_d_o  = event_intr_i | test_q;  // Live HW status or persistent test

      assign status = event_intr_i | test_q;             // Pass-through interrupt state
      wire unused_reg2hw;    
      assign unused_reg2hw = ^reg2hw_intr_state_q_i;
    end
  endgenerate

  // Generate output interrupt line (flopped or pass-through)
  generate
    if (FlopOutput == 1'b1) begin : g_flop_intr
      // Flop the interrupt output to avoid glitching
      always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
          intr_o <= {Width{1'b0}};
        else
          intr_o <= status & reg2hw_intr_enable_q_i; // Masked by enable register
      end
    end else begin : g_passthru_intr
        wire unused_clk;
        wire unused_rst_n;
        assign unused_clk = clk_i;
        assign unused_rst_n = rst_ni;
      // Direct pass-through interrupt output
      assign intr_o = reg2hw_intr_state_q_i & reg2hw_intr_enable_q_i;
    end
  endgenerate

endmodule
