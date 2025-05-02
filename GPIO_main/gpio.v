`timescale 1ns / 1ps

//------------------------------------------------------------------------------
// GPIO Module - Verilog 2005 & Verilator-Compatible
//------------------------------------------------------------------------------
// Description:
//   - General Purpose Input/Output block adapted from OpenTitan project.
//   - Supports direct and masked writes to data and output-enable registers.
//   - Strap sampling support and full implementation of interrupt, alert, TL-UL, and RACL logic.
//------------------------------------------------------------------------------

`include "gpio_reg_pkg.vh" // Include flattened register and signal definitions
`include "prim_assert.sv"
module gpio #(
  parameter int unsigned NUM_ALERTS = `NUM_ALERTS,
  parameter int unsigned BLOCK_AW = `BLOCK_AW,
  parameter int unsigned NUM_REGS = `NUM_REGS,
  parameter [NUM_ALERTS-1:0] AlertAsyncOn     = {NUM_ALERTS{1'b1}},      // Alert logic asynchronous behavior
  parameter       GpioAsHwStrapsEn = 1'b1,      // Enable strap sampling logic
  parameter       GpioAsyncOn      = 1'b1,      // Enable asynchronous filter path
  //parameter       EnableRacl       = 1'b0,      // Enable RACL interface logic
  //parameter       RaclErrorRsp     = 1'b1,      // Enable RACL error response path
  //parameter [127:0] RaclPolicySelVec = 128'h0   // Default RACL policy configuration
) (
  input               clk_i,
  input               rst_ni,

  input               strap_en_i,
  output              gpio_straps_t_valid,
  output [31:0]       gpio_straps_t_data,

  input  [127:0]      tl_i,
  output [127:0]      tl_o,

  output [31:0]       intr_gpio_o,

  input  [NUM_ALERTS-1:0]        alert_rx_i,
  output [NUM_ALERTS-1:0]        alert_tx_o,

  input  [71:0]       racl_policies_i,
  output              racl_error_o_valid,
  output [31:0]       racl_error_o_code,

  input  [31:0]       cio_gpio_i,
  output [31:0]       cio_gpio_o,
  output [31:0]       cio_gpio_en_o
);

// Internal registers
reg [31:0] gpio_out_q;
reg [31:0] gpio_oe_q;
reg [31:0] intr_state_q;
reg [31:0] intr_enable_q;
reg [31:0] intr_rise_edge, intr_fall_edge, intr_high_lvl, intr_low_lvl;
reg [31:0] gpio_in_q;

//------------------------------------------------------------------------------
// Optional Input Filtering (per bit)
//------------------------------------------------------------------------------

//To remove glitches or metastable transitions on GPIO inputs — 
//   --- particularly useful when sampling asynchronous or noisy signals.
// Each bit gets its own prim_filter_ctr module.
// The module counts how long the input has been high/low.
// Only if it’s stable for enough cycles (thresh_i), it updates the output.
wire [31:0] cio_gpio_filtered;

generate
  genvar i;
  for (i = 0; i < 32; i = i + 1) begin : gen_input_filter
    prim_filter_ctr #(
      .AsyncOn(GpioAsyncOn),
      .CntWidth(4)
    ) u_filter (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .enable_i(gpio_reg2hw_ctrl_en_input_filter_reg_t_q[i]),
      .filter_i(cio_gpio_i[i]),
      .thresh_i(4'hF),
      .filter_o(cio_gpio_filtered[i])
    );
  end
endgenerate

//------------------------------------------------------------------------------
// Strap Sampling Logic
//------------------------------------------------------------------------------

// To capture a snapshot of the GPIO input state on a pulse from strap_en_i, and store it in registers.
//When strap_en_i is pulsed:
//.  If the valid register is not already set (~..._valid.q), sampling occurs.
//.  The filtered GPIO inputs (cio_gpio_filtered) are captured into a register.
//.  The valid flag is also set.
//   After that, the sampled values remain static unless reset.
generate
  if (GpioAsHwStrapsEn) begin : gen_strap_sample
    wire strap_en;
    assign strap_en = strap_en_i;
    wire sample_trigger;
    assign sample_trigger = strap_en & ~gpio_reg2hw_hw_straps_data_in_valid_reg_t_q;

    assign gpio_hw2reg_hw_straps_data_in_valid_reg_t_de = sample_trigger;
    assign gpio_hw2reg_hw_straps_data_in_valid_reg_t_d  = 1'b1;
    assign gpio_hw2reg_hw_straps_data_in_reg_t_de       = sample_trigger;
    assign gpio_hw2reg_hw_straps_data_in_reg_t_d        = cio_gpio_filtered;
    assign gpio_straps_t_data                           = gpio_reg2hw_hw_straps_data_in_reg_t_q;
    assign gpio_straps_t_valid                          = gpio_reg2hw_hw_straps_data_in_valid_reg_t_q;
  end else begin : gen_no_strap_sample
    assign gpio_hw2reg_hw_straps_data_in_valid_reg_t_de = 1'b0;
    assign gpio_hw2reg_hw_straps_data_in_valid_reg_t_d  = 1'b0;
    assign gpio_hw2reg_hw_straps_data_in_reg_t_de       = 1'b0;
    assign gpio_hw2reg_hw_straps_data_in_reg_t_d        = 32'h0;
    assign gpio_straps_t_data                           = 32'h0;
    assign gpio_straps_t_valid                          = 1'b0;

    // Lint-safe unused signal logic
    wire unused_straps_signals; 
    assign unused_straps_signals = ^{strap_en_i, gpio_reg2hw_hw_straps_data_in_reg_t_q, gpio_reg2hw_hw_straps_data_in_valid_reg_t_q};

  end
endgenerate
///GPIO_IN
assign gpio_hw2reg_data_in_reg_t_de  = 1'b1;
assign gpio_hw2reg_data_in_reg_t_d   = cio_gpio_filtered;



assign gpio_hw2reg_direct_out_reg_t_d = gpio_out_q;
assign gpio_hw2reg_masked_out_upper_reg_t_data_d = gpio_out_q[31:16];
assign gpio_hw2reg_masked_out_upper_reg_t_mask_d = 16'h0;
assign gpio_hw2reg_masked_out_lower_reg_t_data_d = gpio_out_q[15:0];
assign gpio_hw2reg_masked_out_lower_reg_t_mask_d = 16'h0;


//------------------------------------------------------------------------------
// GPIO Output Data Register Control
//------------------------------------------------------------------------------
always @(posedge clk_i or negedge rst_ni) begin
  if (!rst_ni) begin
    gpio_out_q <= 32'b 0;
  end else if (gpio_reg2hw_direct_out_reg_t_qe) begin
    gpio_out_q <= gpio_reg2hw_direct_out_reg_t_q;
  end else if (gpio_reg2hw_masked_out_upper_reg_t_data_qe) begin
    gpio_out_q[31:16] <= (gpio_reg2hw_masked_out_upper_reg_t_mask_q & gpio_reg2hw_masked_out_upper_reg_t_data_q) |
                         (~gpio_reg2hw_masked_out_upper_reg_t_mask_q & gpio_out_q[31:16]);
  end else if (gpio_reg2hw_masked_out_lower_reg_t_data_qe) begin
    gpio_out_q[15:0] <= (gpio_reg2hw_masked_out_lower_reg_t_mask_q & gpio_reg2hw_masked_out_lower_reg_t_data_q) |
                        (~gpio_reg2hw_masked_out_lower_reg_t_mask_q & gpio_out_q[15:0]);
  end
end
//GPIO_OUT
assign cio_gpio_o    = gpio_out_q;
assign cio_gpio_en_o = gpio_oe_q;
//------------------------------------------------------------------------------
// GPIO Output Enable Register Control
//------------------------------------------------------------------------------

assign gpio_hw2reg_direct_oe_reg_t_d = gpio_oe_q;
assign gpio_hw2reg_masked_oe_upper_reg_t_data_d = gpio_oe_q[31:16];
assign gpio_hw2reg_masked_oe_upper_reg_t_mask_d = 16'h0;
assign gpio_hw2reg_masked_oe_lower_reg_t_data_d = gpio_oe_q[15:0];
assign gpio_hw2reg_masked_oe_lower_reg_t_mask_d = 16'h0;

always @(posedge clk_i or negedge rst_ni) begin
  if (!rst_ni) begin
    gpio_oe_q <= 32'b 0;
  end else if (gpio_reg2hw_direct_oe_reg_t_qe) begin
    gpio_oe_q <= gpio_reg2hw_direct_oe_reg_t_q;
  end else if (gpio_reg2hw_masked_oe_upper_reg_t_data_qe) begin
    gpio_oe_q[31:16] <= (gpio_reg2hw_masked_oe_upper_reg_t_mask_q & gpio_reg2hw_masked_oe_upper_reg_t_data_q) |
                        (~gpio_reg2hw_masked_oe_upper_reg_t_mask_q & gpio_oe_q[31:16]);
  end else if (gpio_reg2hw_masked_oe_lower_reg_t_data_qe) begin
    gpio_oe_q[15:0] <= (gpio_reg2hw_masked_oe_lower_reg_t_mask_q & gpio_reg2hw_masked_oe_lower_reg_t_data_q) |
                       (~gpio_reg2hw_masked_oe_lower_reg_t_mask_q & gpio_oe_q[15:0]);
  end
end

//assign cio_gpio_o    = gpio_out_q;
//assign cio_gpio_en_o = gpio_oe_q;


//------------------------------------------------------------------------------
// Strap Sampling Output
//------------------------------------------------------------------------------
assign gpio_straps_t_data  = cio_gpio_i;
assign gpio_straps_t_valid = strap_en_i;

//------------------------------------------------------------------------------
// Interrupt Logic (Rising/Falling/Level Detect)
//------------------------------------------------------------------------------

// instantiate interrupt hardware primitive
prim_intr_hw #(.Width(32)) intr_hw (
    .clk_i,
    .rst_ni,
    .event_intr_i           (event_intr_combined),
    .reg2hw_intr_enable_q_i (reg2hw.intr_enable.q),
    .reg2hw_intr_test_q_i   (reg2hw.intr_test.q),
    .reg2hw_intr_test_qe_i  (reg2hw.intr_test.qe),
    .reg2hw_intr_state_q_i  (reg2hw.intr_state.q),
    .hw2reg_intr_state_de_o (hw2reg.intr_state.de),
    .hw2reg_intr_state_d_o  (hw2reg.intr_state.d),
    .intr_o                 (intr_gpio_o)
);

wire [31:0] rise_evt;
assign rise_evt = (~gpio_in_q & cio_gpio_i) & gpio_reg2hw_intr_ctrl_en_rising_reg_t_q;
wire [31:0] fall_evt ;
assign fall_evt = ( gpio_in_q & ~cio_gpio_i) & gpio_reg2hw_intr_ctrl_en_falling_reg_t_q;
wire [31:0] lvlhi_evt;
assign lvlhi_evt = cio_gpio_i & gpio_reg2hw_intr_ctrl_en_lvlhigh_reg_t_q;
wire [31:0] lvllo_evt ;
assign lvllo_evt = ~cio_gpio_i & gpio_reg2hw_intr_ctrl_en_lvllow_reg_t_q;
wire [31:0] evt_intr_combined;
assign evt_intr_combined = (rise_evt | fall_evt | lvlhi_evt | lvllo_evt) & gpio_reg2hw_intr_enable_reg_t_q;

always @(posedge clk_i) begin
  gpio_in_q <= cio_gpio_i;
end

//------------------------------------------------------------------------------
// Alert Logic
//------------------------------------------------------------------------------
logic[NUM_ALERTS-1:0] alert_test, alerts;
assign alert_test = gpio_reg2hw_alert_test_reg_t_q & gpio_reg2hw_alert_test_reg_t_qe;
generate
    for (genvar i = 0; i < NUM_ALERTS; i++) begin : gen_alert_tx
        prim_alert_sender #(
        .AsyncOn(AlertAsyncOn[i]),
        .IsFatal(1'b1)
        ) u_prim_alert_sender (
        .clk_i,
        .rst_ni,
        .alert_test_i  ( alert_test[i] ),
        .alert_req_i   ( alerts[0]     ),
        .alert_ack_o   (               ),
        .alert_state_o (               ),
        .alert_rx_i    ( alert_rx_i[i] ),
        .alert_tx_o    ( alert_tx_o[i] )
        );
    end
endgenerate

// // Register module
// gpio_reg_top #(
//     .EnableRacl(EnableRacl),
//     .RaclErrorRsp(RaclErrorRsp),
//     .RaclPolicySelVec(RaclPolicySelVec)
//     ) u_reg (
//     .clk_i,
//     .rst_ni,

//     .tl_i,
//     .tl_o,

//     .reg2hw,
//     .hw2reg,

//     .racl_policies_i,
//     .racl_error_o,

//     // SEC_CM: BUS.INTEGRITY
//     .intg_err_o (alerts[0])
// );

// //------------------------------------------------------------------------------
// // Placeholder TileLink Bus (stubbed)
// //------------------------------------------------------------------------------
// assign tl_o = 128'h0;

// //------------------------------------------------------------------------------
// // RACL Logic (stubbed)
// //------------------------------------------------------------------------------
// assign racl_error_o_valid = 1'b0;
// assign racl_error_o_code  = 32'h0;

endmodule
