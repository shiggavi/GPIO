`timescale 1ns / 1ps


// Combined GPIO Package and Register Definitions

module gpio_reg_pkg;

// Strap Type
typedef struct {
    logic        valid;
    logic [31:0] data;
} gpio_straps_t;

// Parameters
`define NUM_ALERTS 1 
`define BLOCK_AW 7    // Address widths within the block
`define NUM_REGS 18   // No. of registers for every interface

// Register Structure Typedefs
typedef struct {
    logic [31:0] q;
} gpio_reg2hw_intr_state_reg_t;

typedef struct {
    logic [31:0] q;
} gpio_reg2hw_intr_enable_reg_t;

typedef struct {
    logic [31:0] q;
    logic        qe;
} gpio_reg2hw_intr_test_reg_t;

typedef struct {
    logic        q;
    logic        qe;
} gpio_reg2hw_alert_test_reg_t;

typedef struct {
    logic [31:0] q;
    logic        qe;
} gpio_reg2hw_direct_out_reg_t;

typedef struct {
    struct {
        logic [15:0] q;
        logic        qe;
    } mask;
    struct {
        logic [15:0] q;
        logic        qe;
    } data;
} gpio_reg2hw_masked_out_lower_reg_t;

typedef struct {
    struct {
        logic [15:0] q;
        logic        qe;
    } mask;
    struct {
        logic [15:0] q;
        logic        qe;
    } data;
} gpio_reg2hw_masked_out_upper_reg_t;

typedef struct {
    logic [31:0] q;
    logic        qe;
} gpio_reg2hw_direct_oe_reg_t;

typedef struct {
    struct {
        logic [15:0] q;
        logic        qe;
    } mask;
    struct {
        logic [15:0] q;
        logic        qe;
    } data;
} gpio_reg2hw_masked_oe_lower_reg_t;

typedef struct {
    struct {
        logic [15:0] q;
        logic        qe;
    } mask;
    struct {
        logic [15:0] q;
        logic        qe;
    } data;
} gpio_reg2hw_masked_oe_upper_reg_t;

typedef struct {
    logic [31:0] q;
} gpio_reg2hw_intr_ctrl_en_rising_reg_t;

typedef struct {
    logic [31:0] q;
} gpio_reg2hw_intr_ctrl_en_falling_reg_t;

typedef struct {
    logic [31:0] q;
} gpio_reg2hw_intr_ctrl_en_lvlhigh_reg_t;

typedef struct {
    logic [31:0] q;
} gpio_reg2hw_intr_ctrl_en_lvllow_reg_t;

typedef struct {
    logic [31:0] q;
} gpio_reg2hw_ctrl_en_input_filter_reg_t;

typedef struct {
    logic q;
} gpio_reg2hw_hw_straps_data_in_valid_reg_t;

typedef struct {
    logic [31:0] q;
} gpio_reg2hw_hw_straps_data_in_reg_t;

// HW to Register Structures
typedef struct {
    logic [31:0] d;
    logic        de;
} gpio_hw2reg_intr_state_reg_t;

typedef struct {
    logic [31:0] d;
    logic        de;
} gpio_hw2reg_data_in_reg_t;

typedef struct {
    logic [31:0] d;
} gpio_hw2reg_direct_out_reg_t;

typedef struct {
    struct {
        logic [15:0] d;
    } data;
    struct {
        logic [15:0] d;
    } mask;
} gpio_hw2reg_masked_out_lower_reg_t;

typedef struct {
    struct {
        logic [15:0] d;
    } data;
    struct {
        logic [15:0] d;
    } mask;
} gpio_hw2reg_masked_out_upper_reg_t;

typedef struct {
    logic [31:0] d;
} gpio_hw2reg_direct_oe_reg_t;

typedef struct {
    struct {
        logic [15:0] d;
    } data;
    struct {
        logic [15:0] d;
    } mask;
} gpio_hw2reg_masked_oe_lower_reg_t;

typedef struct {
    struct {
        logic [15:0] d;
    } data;
    struct {
        logic [15:0] d;
    } mask;
} gpio_hw2reg_masked_oe_upper_reg_t;

typedef struct {
    logic d;
    logic de;
} gpio_hw2reg_hw_straps_data_in_valid_reg_t;

typedef struct {
    logic [31:0] d;
    logic        de;
} gpio_hw2reg_hw_straps_data_in_reg_t;

// Register -> HW type
typedef struct {
    gpio_reg2hw_intr_state_reg_t             intr_state;
    gpio_reg2hw_intr_enable_reg_t            intr_enable;
    gpio_reg2hw_intr_test_reg_t              intr_test;
    gpio_reg2hw_alert_test_reg_t             alert_test;
    gpio_reg2hw_direct_out_reg_t             direct_out;
    gpio_reg2hw_masked_out_lower_reg_t       masked_out_lower;
    gpio_reg2hw_masked_out_upper_reg_t       masked_out_upper;
    gpio_reg2hw_direct_oe_reg_t              direct_oe;
    gpio_reg2hw_masked_oe_lower_reg_t        masked_oe_lower;
    gpio_reg2hw_masked_oe_upper_reg_t        masked_oe_upper;
    gpio_reg2hw_intr_ctrl_en_rising_reg_t    intr_ctrl_en_rising;
    gpio_reg2hw_intr_ctrl_en_falling_reg_t   intr_ctrl_en_falling;
    gpio_reg2hw_intr_ctrl_en_lvlhigh_reg_t   intr_ctrl_en_lvlhigh;
    gpio_reg2hw_intr_ctrl_en_lvllow_reg_t    intr_ctrl_en_lvllow;
    gpio_reg2hw_ctrl_en_input_filter_reg_t   ctrl_en_input_filter;
    gpio_reg2hw_hw_straps_data_in_valid_reg_t hw_straps_data_in_valid;
    gpio_reg2hw_hw_straps_data_in_reg_t      hw_straps_data_in;
} gpio_reg2hw_t;

// HW -> Register type
typedef struct {
    gpio_hw2reg_intr_state_reg_t             intr_state;
    gpio_hw2reg_data_in_reg_t                data_in;
    gpio_hw2reg_direct_out_reg_t             direct_out;
    gpio_hw2reg_masked_out_lower_reg_t       masked_out_lower;
    gpio_hw2reg_masked_out_upper_reg_t       masked_out_upper;
    gpio_hw2reg_direct_oe_reg_t              direct_oe;
    gpio_hw2reg_masked_oe_lower_reg_t        masked_oe_lower;
    gpio_hw2reg_masked_oe_upper_reg_t        masked_oe_upper;
    gpio_hw2reg_hw_straps_data_in_valid_reg_t hw_straps_data_in_valid;
    gpio_hw2reg_hw_straps_data_in_reg_t      hw_straps_data_in;
} gpio_hw2reg_t;

// Register Offsets
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

// Reset Values
`define GPIO_INTR_TEST_RESVAL            32'h0
`define GPIO_ALERT_TEST_RESVAL           1'h0
`define GPIO_DIRECT_OUT_RESVAL           32'h0
`define GPIO_MASKED_OUT_LOWER_RESVAL     32'h0
`define GPIO_MASKED_OUT_UPPER_RESVAL     32'h0
`define GPIO_DIRECT_OE_RESVAL            32'h0
`define GPIO_MASKED_OE_LOWER_RESVAL      32'h0
`define GPIO_MASKED_OE_UPPER_RESVAL      32'h0

// Register Index
localparam GPIO_INTR_STATE = 0;
localparam GPIO_INTR_ENABLE = 1;
localparam GPIO_INTR_TEST = 2;
localparam GPIO_ALERT_TEST = 3;
localparam GPIO_DATA_IN = 4;
localparam GPIO_DIRECT_OUT = 5;
localparam GPIO_MASKED_OUT_LOWER = 6;
localparam GPIO_MASKED_OUT_UPPER = 7;
localparam GPIO_DIRECT_OE = 8;
localparam GPIO_MASKED_OE_LOWER = 9;
localparam GPIO_MASKED_OE_UPPER = 10;
localparam GPIO_INTR_CTRL_EN_RISING = 11;
localparam GPIO_INTR_CTRL_EN_FALLING = 12;
localparam GPIO_INTR_CTRL_EN_LVLHIGH = 13;
localparam GPIO_INTR_CTRL_EN_LVLLOW = 14;
localparam GPIO_CTRL_EN_INPUT_FILTER = 15;
localparam GPIO_HW_STRAPS_DATA_IN_VALID = 16;
localparam GPIO_HW_STRAPS_DATA_IN = 17;

// Permission Macros (matches original 4-bit per register permissions)
// Register width information to check illegal writes

`define GPIO_PERMIT { \
    4'b1111, /* [0] GPIO_INTR_STATE */ \
    4'b1111, /* [1] GPIO_INTR_ENABLE */ \
    4'b1111, /* [2] GPIO_INTR_TEST */ \
    4'b0001, /* [3] GPIO_ALERT_TEST */ \
    4'b1111, /* [4] GPIO_DATA_IN */ \
    4'b1111, /* [5] GPIO_DIRECT_OUT */ \
    4'b1111, /* [6] GPIO_MASKED_OUT_LOWER */ \
    4'b1111, /* [7] GPIO_MASKED_OUT_UPPER */ \
    4'b1111, /* [8] GPIO_DIRECT_OE */ \
    4'b1111, /* [9] GPIO_MASKED_OE_LOWER */ \
    4'b1111, /* [10] GPIO_MASKED_OE_UPPER */ \
    4'b1111, /* [11] GPIO_INTR_CTRL_EN_RISING */ \
    4'b1111, /* [12] GPIO_INTR_CTRL_EN_FALLING */ \
    4'b1111, /* [13] GPIO_INTR_CTRL_EN_LVLHIGH */ \
    4'b1111, /* [14] GPIO_INTR_CTRL_EN_LVLLOW */ \
    4'b1111, /* [15] GPIO_CTRL_EN_INPUT_FILTER */ \
    4'b0001, /* [16] GPIO_HW_STRAPS_DATA_IN_VALID */ \
    4'b1111  /* [17] GPIO_HW_STRAPS_DATA_IN */ \
}

endmodule 