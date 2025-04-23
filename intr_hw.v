// Primitive interrupt handler module (Verilog compatible)

// Block for generating CIP interrupts in peripherals.

// This block generates both the level-triggered wired interrupt signal intr_o and also updates
// the value of the INTR_STATE register. Together, the signal and register make up the two
// externally-visible indications of of the interrupt state.
//
// This assumes the existence of three external controller registers, which
// interface with this module via the standard reggen reg2hw/hw2reg signals. The 3 registers are:
// - INTR_ENABLE : enables/masks the output of INTR_STATE as the intr_o signal
// - INTR_STATE  : the current state of the interrupt (may be RO or W1C depending on "IntrT")
// - INTR_TEST   : sw-access-only register which asserts the interrupt for testing purposes
`timescale 1ns / 1ps

module prim_intr_hw #(
    parameter Width = 1,          // Interrupt vector width
    parameter FlopOutput = 1,     // Output flop control
    parameter IntrT = "Event"           // 0 = Event, 1 = Status
) (
    // Event
    input clk_i,
    input rst_ni,
    input [Width-1:0] event_intr_i,
    
    // Register interface
    input [Width-1:0] reg2hw_intr_enable_q_i,
    input [Width-1:0] reg2hw_intr_test_q_i,
    input reg2hw_intr_test_qe_i,
    input [Width-1:0] reg2hw_intr_state_q_i,
    output reg hw2reg_intr_state_de_o,
    output reg [Width-1:0] hw2reg_intr_state_d_o,
    
    // Output interrupt
    output reg [Width-1:0] intr_o
);

// As the wired interrupt signal intr_o is a level-triggered interrupt, the upstream consumer sw
  // has two options to make forward progress when this signal is asserted:
  // - Mask the interrupt, by setting INTR_ENABLE = 1'b0 or masking/enabling at an upstream consumer.
  // - Interact with the peripheral in some user-defined way that clears the signal.
  // To make this user-defined interaction ergonomic from a SW-perspective, we have defined
  // two common patterns for typical interrupt-triggering events, *Status* and *Event*.
  // - *Event* is useful for capturing a momentary assertion of the input signal.
  //   - INTR_STATE/intr_o is set to '1 upon the event occurring.
  //   - INTR_STATE/intr_o remain set until software writes-1-to-clear to INTR_STATE.
  // - *Status* captures a persistent conditional assertion that requires intervention to de-assert.
  //   - Until the root cause is alleviated, the interrupt output (while enabled) is continuously asserted.
  //   - INTR_STATE for *status* interrupts is RO (it simply presents the raw HW input signal).
  //   - If the root_cause is cleared, INTR_STATE/intr_o also clears automatically.
  
reg [Width-1:0] status;

generate
    // Event-type interrupt handling
    if (IntrT == "Event") begin : g_intr_event
        reg [Width-1:0] new_event;
        
        always @* begin
            new_event = ({Width{reg2hw_intr_test_qe_i}} & reg2hw_intr_test_q_i) | event_intr_i;
            hw2reg_intr_state_de_o = |new_event;
            // for scalar interrupts, this resolves to '1' with new event
            // for vector interrupts, new events are OR'd in to existing interrupt state
            hw2reg_intr_state_d_o = new_event | reg2hw_intr_state_q_i;
            status = reg2hw_intr_state_q_i;
        end
    end 
    // Status-type interrupt handling
    else if (IntrT == "Status") begin : g_intr_status
        reg [Width-1:0] test_q;
        
        always @(posedge clk_i or negedge rst_ni) begin
            if (!rst_ni) test_q <= 0;
            else if (reg2hw_intr_test_qe_i) test_q <= reg2hw_intr_test_q_i;
        end
        
        // In Status type, INTR_STATE is better to be external type and R0
        always @* begin
            hw2reg_intr_state_de_o = 1'b1;
            hw2reg_intr_state_d_o = event_intr_i | test_q;
            status = event_intr_i | test_q;
        end
        
        // Unused signal tie-off
        wire unused_reg2hw = |reg2hw_intr_state_q_i;
    end
    
    // Error check: Ensuring only valid interrupt types are used
    // Using ifndef for ease during synthesis. Synthesis will not accept $finish. If ifndef used, synthesis will ignore $finish.
    else begin: g_invalid_intr
      `ifndef ERROR_CHECK
      initial begin
        $display("ERROR: [%m] Invalid IntrT value '%s'. Must be 'Event' or 'Status'.", IntrT);
        $finish;
      end
      `endif
    end

endgenerate

generate
    if (FlopOutput) begin : gen_flop_intr_output
        always @(posedge clk_i or negedge rst_ni) begin
            if (!rst_ni) intr_o <= 0;
            else intr_o <= status & reg2hw_intr_enable_q_i;
        end
    end else begin : gen_intr_passthrough_output
        always @* begin
            intr_o = status & reg2hw_intr_enable_q_i;
        end
        
        // Unused signal tie-offs
        wire unused_clk = clk_i;
        wire unused_rst = rst_ni;
    end
endgenerate

endmodule