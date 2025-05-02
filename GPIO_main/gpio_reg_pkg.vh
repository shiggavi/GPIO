`ifndef GPIO_REG_PKG_VH
`define GPIO_REG_PKG_VH

`timescale 1ns / 1ps

// GPIO Register Package - Verilog-2005 and Verilator Friendly Format
// This module contains all necessary flattened signals for register access

//module gpio_reg_pkg;

// ----------------------------------------------------------------------------
// Parameters for register definitions
// ----------------------------------------------------------------------------
`define NUM_ALERTS 1                     // Number of alert signals
`define BLOCK_AW 7                       // Address width for GPIO block
`define NUM_REGS 18                      // Number of total GPIO registers

// ----------------------------------------------------------------------------
// Strap Type Wires
// ----------------------------------------------------------------------------
wire        gpio_straps_t_valid;        // Strap valid flag
wire [31:0] gpio_straps_t_data;         // Strap sampled data

// ----------------------------------------------------------------------------
// Register-to-Hardware Interface Wires
// ----------------------------------------------------------------------------
wire [31:0] gpio_reg2hw_intr_state_reg_t_q;       // Interrupt state
wire [31:0] gpio_reg2hw_intr_enable_reg_t_q;      // Interrupt enable
wire [31:0] gpio_reg2hw_intr_test_reg_t_q;        // Interrupt test
wire        gpio_reg2hw_intr_test_reg_t_qe;       // Interrupt test enable

wire        gpio_reg2hw_alert_test_reg_t_q;       // Alert test
wire        gpio_reg2hw_alert_test_reg_t_qe;      // Alert test enable

wire [31:0] gpio_reg2hw_direct_out_reg_t_q;       // Direct output value
wire        gpio_reg2hw_direct_out_reg_t_qe;      // Direct output enable

// Masked output lower half
wire [15:0] gpio_reg2hw_masked_out_lower_reg_t_mask_q;
wire        gpio_reg2hw_masked_out_lower_reg_t_mask_qe;
wire [15:0] gpio_reg2hw_masked_out_lower_reg_t_data_q;
wire        gpio_reg2hw_masked_out_lower_reg_t_data_qe;

// Masked output upper half
wire [15:0] gpio_reg2hw_masked_out_upper_reg_t_mask_q;
wire        gpio_reg2hw_masked_out_upper_reg_t_mask_qe;
wire [15:0] gpio_reg2hw_masked_out_upper_reg_t_data_q;
wire        gpio_reg2hw_masked_out_upper_reg_t_data_qe;

// Direct output enable register
wire [31:0] gpio_reg2hw_direct_oe_reg_t_q;
wire        gpio_reg2hw_direct_oe_reg_t_qe;

// Masked OE lower
wire [15:0] gpio_reg2hw_masked_oe_lower_reg_t_mask_q;
wire        gpio_reg2hw_masked_oe_lower_reg_t_mask_qe;
wire [15:0] gpio_reg2hw_masked_oe_lower_reg_t_data_q;
wire        gpio_reg2hw_masked_oe_lower_reg_t_data_qe;

// Masked OE upper
wire [15:0] gpio_reg2hw_masked_oe_upper_reg_t_mask_q;
wire        gpio_reg2hw_masked_oe_upper_reg_t_mask_qe;
wire [15:0] gpio_reg2hw_masked_oe_upper_reg_t_data_q;
wire        gpio_reg2hw_masked_oe_upper_reg_t_data_qe;

// Interrupt controls
wire [31:0] gpio_reg2hw_intr_ctrl_en_rising_reg_t_q;
wire [31:0] gpio_reg2hw_intr_ctrl_en_falling_reg_t_q;
wire [31:0] gpio_reg2hw_intr_ctrl_en_lvlhigh_reg_t_q;
wire [31:0] gpio_reg2hw_intr_ctrl_en_lvllow_reg_t_q;

// Input filter enable
wire [31:0] gpio_reg2hw_ctrl_en_input_filter_reg_t_q;

// Strap hardware sampled data
wire        gpio_reg2hw_hw_straps_data_in_valid_reg_t_q;
wire [31:0] gpio_reg2hw_hw_straps_data_in_reg_t_q;

// ----------------------------------------------------------------------------
// Hardware-to-Register Interface Wires
// ----------------------------------------------------------------------------
wire [31:0] gpio_hw2reg_intr_state_reg_t_d;
wire        gpio_hw2reg_intr_state_reg_t_de;

wire [31:0] gpio_hw2reg_data_in_reg_t_d;
wire        gpio_hw2reg_data_in_reg_t_de;

wire [31:0] gpio_hw2reg_direct_out_reg_t_d;

wire [15:0] gpio_hw2reg_masked_out_lower_reg_t_data_d;
wire [15:0] gpio_hw2reg_masked_out_lower_reg_t_mask_d;

wire [15:0] gpio_hw2reg_masked_out_upper_reg_t_data_d;
wire [15:0] gpio_hw2reg_masked_out_upper_reg_t_mask_d;

wire [31:0] gpio_hw2reg_direct_oe_reg_t_d;

wire [15:0] gpio_hw2reg_masked_oe_lower_reg_t_data_d;
wire [15:0] gpio_hw2reg_masked_oe_lower_reg_t_mask_d;

wire [15:0] gpio_hw2reg_masked_oe_upper_reg_t_data_d;
wire [15:0] gpio_hw2reg_masked_oe_upper_reg_t_mask_d;

wire        gpio_hw2reg_hw_straps_data_in_valid_reg_t_d;
wire        gpio_hw2reg_hw_straps_data_in_valid_reg_t_de;
wire [31:0] gpio_hw2reg_hw_straps_data_in_reg_t_d;
wire        gpio_hw2reg_hw_straps_data_in_reg_t_de;

// ----------------------------------------------------------------------------
// Register Offsets (used for decoding address map)
// ----------------------------------------------------------------------------
`define GPIO_INTR_STATE_OFFSET              7'h00
`define GPIO_INTR_ENABLE_OFFSET             7'h04
`define GPIO_INTR_TEST_OFFSET               7'h08
`define GPIO_ALERT_TEST_OFFSET              7'h0C
`define GPIO_DATA_IN_OFFSET                 7'h10
`define GPIO_DIRECT_OUT_OFFSET              7'h14
`define GPIO_MASKED_OUT_LOWER_OFFSET        7'h18
`define GPIO_MASKED_OUT_UPPER_OFFSET        7'h1C
`define GPIO_DIRECT_OE_OFFSET               7'h20
`define GPIO_MASKED_OE_LOWER_OFFSET         7'h24
`define GPIO_MASKED_OE_UPPER_OFFSET         7'h28
`define GPIO_INTR_CTRL_EN_RISING_OFFSET     7'h2C
`define GPIO_INTR_CTRL_EN_FALLING_OFFSET    7'h30
`define GPIO_INTR_CTRL_EN_LVLHIGH_OFFSET    7'h34
`define GPIO_INTR_CTRL_EN_LVLLOW_OFFSET     7'h38
`define GPIO_CTRL_EN_INPUT_FILTER_OFFSET    7'h3C
`define GPIO_HW_STRAPS_DATA_IN_VALID_OFFSET 7'h40
`define GPIO_HW_STRAPS_DATA_IN_OFFSET       7'h44

// ----------------------------------------------------------------------------
// Reset Values for Registers
// ----------------------------------------------------------------------------
`define GPIO_INTR_TEST_RESVAL            32'h0
`define GPIO_ALERT_TEST_RESVAL           1'h0
`define GPIO_DIRECT_OUT_RESVAL           32'h0
`define GPIO_MASKED_OUT_LOWER_RESVAL     32'h0
`define GPIO_MASKED_OUT_UPPER_RESVAL     32'h0
`define GPIO_DIRECT_OE_RESVAL            32'h0
`define GPIO_MASKED_OE_LOWER_RESVAL      32'h0
`define GPIO_MASKED_OE_UPPER_RESVAL      32'h0

// ----------------------------------------------------------------------------
// Register Index Constants (use for index-based access)
// ----------------------------------------------------------------------------
localparam GPIO_INTR_STATE              = 0;
localparam GPIO_INTR_ENABLE             = 1;
localparam GPIO_INTR_TEST               = 2;
localparam GPIO_ALERT_TEST              = 3;
localparam GPIO_DATA_IN                 = 4;
localparam GPIO_DIRECT_OUT              = 5;
localparam GPIO_MASKED_OUT_LOWER        = 6;
localparam GPIO_MASKED_OUT_UPPER        = 7;
localparam GPIO_DIRECT_OE               = 8;
localparam GPIO_MASKED_OE_LOWER         = 9;
localparam GPIO_MASKED_OE_UPPER         = 10;
localparam GPIO_INTR_CTRL_EN_RISING     = 11;
localparam GPIO_INTR_CTRL_EN_FALLING    = 12;
localparam GPIO_INTR_CTRL_EN_LVLHIGH    = 13;
localparam GPIO_INTR_CTRL_EN_LVLLOW     = 14;
localparam GPIO_CTRL_EN_INPUT_FILTER    = 15;
localparam GPIO_HW_STRAPS_DATA_IN_VALID = 16;
localparam GPIO_HW_STRAPS_DATA_IN       = 17;

// ----------------------------------------------------------------------------
// Permission Field (4-bit value per register)
// ----------------------------------------------------------------------------
`define GPIO_PERMIT { \
    4'b1111, /* [00] INTR_STATE */ \
    4'b1111, /* [01] INTR_ENABLE */ \
    4'b1111, /* [02] INTR_TEST */ \
    4'b0001, /* [03] ALERT_TEST */ \
    4'b1111, /* [04] DATA_IN */ \
    4'b1111, /* [05] DIRECT_OUT */ \
    4'b1111, /* [06] MASKED_OUT_LOWER */ \
    4'b1111, /* [07] MASKED_OUT_UPPER */ \
    4'b1111, /* [08] DIRECT_OE */ \
    4'b1111, /* [09] MASKED_OE_LOWER */ \
    4'b1111, /* [10] MASKED_OE_UPPER */ \
    4'b1111, /* [11] INTR_CTRL_EN_RISING */ \
    4'b1111, /* [12] INTR_CTRL_EN_FALLING */ \
    4'b1111, /* [13] INTR_CTRL_EN_LVLHIGH */ \
    4'b1111, /* [14] INTR_CTRL_EN_LVLLOW */ \
    4'b1111, /* [15] CTRL_EN_INPUT_FILTER */ \
    4'b0001, /* [16] HW_STRAPS_DATA_IN_VALID */ \
    4'b1111  /* [17] HW_STRAPS_DATA_IN */ \
}

//endmodule
`endif // GPIO_REG_PKG_VH
