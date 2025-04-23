

`timescale 1ns / 1ps

module prim_mubi;

//--------------------------------------------------------------
// 4-Bit Multi-Bit (MuBi) Definitions
//--------------------------------------------------------------
localparam MuBi4Width = 4;
localparam [MuBi4Width-1:0] MuBi4True = 4'h6;   // Enabled
localparam [MuBi4Width-1:0] MuBi4False = 4'h9;  // Disabled

// Required for multibit functions below to work
// True and False should be complementary
`ifndef check_mubi
initial begin
  if (MuBi4True !== ~MuBi4False) begin
    $display("ERROR: MuBi4True and MuBi4False are not complementary!");
    $finish;
  end
end
`endif 

// Test whether the multibit value is one of the valid enumerations
function  mubi4_test_invalid;
  input [MuBi4Width-1:0] val;
  begin
    mubi4_test_invalid = (val !== MuBi4True) && (val !== MuBi4False);
  end
endfunction

// Convert a 1 input value to a mubi output
function  [MuBi4Width-1:0] mubi4_bool_to_mubi;
  input val;
  begin
    mubi4_bool_to_mubi = val ? MuBi4True : MuBi4False;
  end
endfunction

// Test whether the multibit value signals an "enabled" condition.
// The strict version of this function requires the multibit value to equal True.
function  mubi4_test_true_strict;
  input [MuBi4Width-1:0] val;
  begin
    mubi4_test_true_strict = (val === MuBi4True);
  end
endfunction

// Test whether the multibit value signals a "disabled" condition.
// The strict version of this function requires the multibit value to equal False.
function  mubi4_test_false_strict;
  input [MuBi4Width-1:0] val;
  begin
    mubi4_test_false_strict = (val === MuBi4False);
  end
endfunction

// Test whether the multibit value signals an "enabled" condition.
// The loose version of this function interprets all values other than False as "enabled".
function automatic mubi4_test_true_loose;
  input [MuBi4Width-1:0] val;
  begin
    mubi4_test_true_loose = (val !== MuBi4False);
  end
endfunction

// Test whether the multibit value signals a "disabled" condition.
// The loose version of this function interprets all values other than True as "disabled".
function automatic mubi4_test_false_loose;
  input [MuBi4Width-1:0] val;
  begin
    mubi4_test_false_loose = (val !== MuBi4True);
  end
endfunction

// Performs a logical OR operation between two multibit values.
// This treats "act" as logical 1, and all other values are treated as 0.
function automatic [MuBi4Width-1:0] mubi4_or;
  input [MuBi4Width-1:0] a, b, act;
  reg [MuBi4Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi4Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] || b[k]) : (a[k] && b[k]);
    end
    mubi4_or = out;
  end
endfunction

// Performs a logical AND operation between two multibit values.
// This treats "act" as logical 1, and all other values are treated as 0. 
function automatic [MuBi4Width-1:0] mubi4_and;
  input [MuBi4Width-1:0] a, b, act;
  reg [MuBi4Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi4Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] && b[k]) : (a[k] || b[k]);
    end
    mubi4_and = out;
  end
endfunction

// Performs a logical OR operation between two multibit values.
// This treats "True" as logical 1, and all other values are treated as 0.
function automatic [MuBi4Width-1:0] mubi4_or_hi;
  input [MuBi4Width-1:0] a, b;
  begin
    mubi4_or_hi = mubi4_or(a, b, MuBi4True);
  end
endfunction

// Performs a logical AND operation between two multibit values.
// This treats "True" as logical 1, and all other values are treated as 0.
function automatic [MuBi4Width-1:0] mubi4_and_hi;
  input [MuBi4Width-1:0] a, b;
  begin
    mubi4_and_hi = mubi4_and(a, b, MuBi4True);
  end
endfunction

// Performs a logical OR operation between two multibit values.
// This treats "False" as logical 1, and all other values are treated as 0.
function automatic [MuBi4Width-1:0] mubi4_or_lo;
  input [MuBi4Width-1:0] a, b;
  begin
    mubi4_or_lo = mubi4_or(a, b, MuBi4False);
  end
endfunction

// Performs a logical AND operation between two multibit values.
// This treats "False" as logical 1, and all other values are treated as 0.
function automatic [MuBi4Width-1:0] mubi4_and_lo;
  input [MuBi4Width-1:0] a, b;
  begin
    mubi4_and_lo = mubi4_and(a, b, MuBi4False);
  end
endfunction


//--------------------------------------------------------------
// 8-Bit Multi-Bit (MuBi) Definitions
//--------------------------------------------------------------

localparam MuBi8Width = 8;
localparam [MuBi8Width-1:0] MuBi8True = 8'h96;   // Enabled
localparam [MuBi8Width-1:0] MuBi8False = 8'h69;  // Disabled

initial begin
  if (MuBi8True !== ~MuBi8False) begin
    $display("ERROR: MuBi8True and MuBi8False are not complementary!");
    $finish;
  end
end

function automatic mubi8_test_invalid;
  input [MuBi8Width-1:0] val;
  begin
    mubi8_test_invalid = (val !== MuBi8True) && (val !== MuBi8False);
  end
endfunction

function automatic [MuBi8Width-1:0] mubi8_bool_to_mubi;
  input val;
  begin
    mubi8_bool_to_mubi = val ? MuBi8True : MuBi8False;
  end
endfunction

function automatic mubi8_test_true_strict;
  input [MuBi8Width-1:0] val;
  begin
    mubi8_test_true_strict = (val === MuBi8True);
  end
endfunction

function automatic mubi8_test_false_strict;
  input [MuBi8Width-1:0] val;
  begin
    mubi8_test_false_strict = (val === MuBi8False);
  end
endfunction

function automatic mubi8_test_true_loose;
  input [MuBi8Width-1:0] val;
  begin
    mubi8_test_true_loose = (val !== MuBi8False);
  end
endfunction

function automatic mubi8_test_false_loose;
  input [MuBi8Width-1:0] val;
  begin
    mubi8_test_false_loose = (val !== MuBi8True);
  end
endfunction

function automatic [MuBi8Width-1:0] mubi8_or;
  input [MuBi8Width-1:0] a, b, act;
  reg [MuBi8Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi8Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] || b[k]) : (a[k] && b[k]);
    end
    mubi8_or = out;
  end
endfunction

function automatic [MuBi8Width-1:0] mubi8_and;
  input [MuBi8Width-1:0] a, b, act;
  reg [MuBi8Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi8Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] && b[k]) : (a[k] || b[k]);
    end
    mubi8_and = out;
  end
endfunction

function automatic [MuBi8Width-1:0] mubi8_or_hi;
  input [MuBi8Width-1:0] a, b;
  begin
    mubi8_or_hi = mubi8_or(a, b, MuBi8True);
  end
endfunction

function automatic [MuBi8Width-1:0] mubi8_and_hi;
  input [MuBi8Width-1:0] a, b;
  begin
    mubi8_and_hi = mubi8_and(a, b, MuBi8True);
  end
endfunction

function automatic [MuBi8Width-1:0] mubi8_or_lo;
  input [MuBi8Width-1:0] a, b;
  begin
    mubi8_or_lo = mubi8_or(a, b, MuBi8False);
  end
endfunction

function automatic [MuBi8Width-1:0] mubi8_and_lo;
  input [MuBi8Width-1:0] a, b;
  begin
    mubi8_and_lo = mubi8_and(a, b, MuBi8False);
  end
endfunction


//--------------------------------------------------------------
// 12-Bit Multi-Bit (MuBi) Definitions
//--------------------------------------------------------------

localparam MuBi12Width = 12;
localparam [MuBi12Width-1:0] MuBi12True = 12'h696;   // Enabled (0110_1001_0110)
localparam [MuBi12Width-1:0] MuBi12False = 12'h969;  // Disabled (1001_0110_1001)

initial begin
  if (MuBi12True !== ~MuBi12False) begin
    $display("ERROR: MuBi12True and MuBi12False are not complementary!");
    $finish;
  end
end

function automatic mubi12_test_invalid;
  input [MuBi12Width-1:0] val;
  begin
    mubi12_test_invalid = (val !== MuBi12True) && (val !== MuBi12False);
  end
endfunction

function automatic [MuBi12Width-1:0] mubi12_bool_to_mubi;
  input val;
  begin
    mubi12_bool_to_mubi = val ? MuBi12True : MuBi12False;
  end
endfunction

function automatic mubi12_test_true_strict;
  input [MuBi12Width-1:0] val;
  begin
    mubi12_test_true_strict = (val === MuBi12True);
  end
endfunction

function automatic mubi12_test_false_strict;
  input [MuBi12Width-1:0] val;
  begin
    mubi12_test_false_strict = (val === MuBi12False);
  end
endfunction

function automatic mubi12_test_true_loose;
  input [MuBi12Width-1:0] val;
  begin
    mubi12_test_true_loose = (val !== MuBi12False);
  end
endfunction

function automatic mubi12_test_false_loose;
  input [MuBi12Width-1:0] val;
  begin
    mubi12_test_false_loose = (val !== MuBi12True);
  end
endfunction

function automatic [MuBi12Width-1:0] mubi12_or;
  input [MuBi12Width-1:0] a, b, act;
  reg [MuBi12Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi12Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] || b[k]) : (a[k] && b[k]);
    end
    mubi12_or = out;
  end
endfunction

function automatic [MuBi12Width-1:0] mubi12_and;
  input [MuBi12Width-1:0] a, b, act;
  reg [MuBi12Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi12Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] && b[k]) : (a[k] || b[k]);
    end
    mubi12_and = out;
  end
endfunction

function automatic [MuBi12Width-1:0] mubi12_or_hi;
  input [MuBi12Width-1:0] a, b;
  begin
    mubi12_or_hi = mubi12_or(a, b, MuBi12True);
  end
endfunction

function automatic [MuBi12Width-1:0] mubi12_and_hi;
  input [MuBi12Width-1:0] a, b;
  begin
    mubi12_and_hi = mubi12_and(a, b, MuBi12True);
  end
endfunction

function automatic [MuBi12Width-1:0] mubi12_or_lo;
  input [MuBi12Width-1:0] a, b;
  begin
    mubi12_or_lo = mubi12_or(a, b, MuBi12False);
  end
endfunction

function automatic [MuBi12Width-1:0] mubi12_and_lo;
  input [MuBi12Width-1:0] a, b;
  begin
    mubi12_and_lo = mubi12_and(a, b, MuBi12False);
  end
endfunction


//--------------------------------------------------------------
// 16-Bit Multi-Bit (MuBi) Definitions
//--------------------------------------------------------------

localparam MuBi16Width = 16;
localparam [MuBi16Width-1:0] MuBi16True = 16'h9696;   // Enabled (1001_0110_1001_0110)
localparam [MuBi16Width-1:0] MuBi16False = 16'h6969;  // Disabled (0110_1001_0110_1001)

initial begin
  if (MuBi16True !== ~MuBi16False) begin
    $display("ERROR: MuBi16True and MuBi16False are not complementary!");
    $finish;
  end
end

function automatic mubi16_test_invalid;
  input [MuBi16Width-1:0] val;
  begin
    mubi16_test_invalid = (val !== MuBi16True) && (val !== MuBi16False);
  end
endfunction

function automatic [MuBi16Width-1:0] mubi16_bool_to_mubi;
  input val;
  begin
    mubi16_bool_to_mubi = val ? MuBi16True : MuBi16False;
  end
endfunction

function automatic mubi16_test_true_strict;
  input [MuBi16Width-1:0] val;
  begin
    mubi16_test_true_strict = (val === MuBi16True);
  end
endfunction

function automatic mubi16_test_false_strict;
  input [MuBi16Width-1:0] val;
  begin
    mubi16_test_false_strict = (val === MuBi16False);
  end
endfunction

function automatic mubi16_test_true_loose;
  input [MuBi16Width-1:0] val;
  begin
    mubi16_test_true_loose = (val !== MuBi16False);
  end
endfunction

function automatic mubi16_test_false_loose;
  input [MuBi16Width-1:0] val;
  begin
    mubi16_test_false_loose = (val !== MuBi16True);
  end
endfunction

function automatic [MuBi16Width-1:0] mubi16_or;
  input [MuBi16Width-1:0] a, b, act;
  reg [MuBi16Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi16Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] || b[k]) : (a[k] && b[k]);
    end
    mubi16_or = out;
  end
endfunction

function automatic [MuBi16Width-1:0] mubi16_and;
  input [MuBi16Width-1:0] a, b, act;
  reg [MuBi16Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi16Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] && b[k]) : (a[k] || b[k]);
    end
    mubi16_and = out;
  end
endfunction

function automatic [MuBi16Width-1:0] mubi16_or_hi;
  input [MuBi16Width-1:0] a, b;
  begin
    mubi16_or_hi = mubi16_or(a, b, MuBi16True);
  end
endfunction

function automatic [MuBi16Width-1:0] mubi16_and_hi;
  input [MuBi16Width-1:0] a, b;
  begin
    mubi16_and_hi = mubi16_and(a, b, MuBi16True);
  end
endfunction

function automatic [MuBi16Width-1:0] mubi16_or_lo;
  input [MuBi16Width-1:0] a, b;
  begin
    mubi16_or_lo = mubi16_or(a, b, MuBi16False);
  end
endfunction

function automatic [MuBi16Width-1:0] mubi16_and_lo;
  input [MuBi16Width-1:0] a, b;
  begin
    mubi16_and_lo = mubi16_and(a, b, MuBi16False);
  end
endfunction


//--------------------------------------------------------------
// 20-Bit Multi-Bit (MuBi) Definitions
//--------------------------------------------------------------

localparam MuBi20Width = 20;
localparam [MuBi20Width-1:0] MuBi20True = 20'h69696;   // Enabled 
localparam [MuBi20Width-1:0] MuBi20False = 20'h96969;  // Disabled

initial begin
  if (MuBi20True !== ~MuBi20False) begin
    $display("ERROR: MuBi20True and MuBi20False are not complementary!");
    $finish;
  end
end

function automatic mubi20_test_invalid;
  input [MuBi20Width-1:0] val;
  begin
    mubi20_test_invalid = (val !== MuBi20True) && (val !== MuBi20False);
  end
endfunction

function automatic [MuBi20Width-1:0] mubi20_bool_to_mubi;
  input val;
  begin
    mubi20_bool_to_mubi = val ? MuBi20True : MuBi20False;
  end
endfunction

function automatic mubi20_test_true_strict;
  input [MuBi20Width-1:0] val;
  begin
    mubi20_test_true_strict = (val === MuBi20True);
  end
endfunction

function automatic mubi20_test_false_strict;
  input [MuBi20Width-1:0] val;
  begin
    mubi20_test_false_strict = (val === MuBi20False);
  end
endfunction

function automatic mubi20_test_true_loose;
  input [MuBi20Width-1:0] val;
  begin
    mubi20_test_true_loose = (val !== MuBi20False);
  end
endfunction

function automatic mubi20_test_false_loose;
  input [MuBi20Width-1:0] val;
  begin
    mubi20_test_false_loose = (val !== MuBi20True);
  end
endfunction

function automatic [MuBi20Width-1:0] mubi20_or;
  input [MuBi20Width-1:0] a, b, act;
  reg [MuBi20Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi20Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] || b[k]) : (a[k] && b[k]);
    end
    mubi20_or = out;
  end
endfunction

function automatic [MuBi20Width-1:0] mubi20_and;
  input [MuBi20Width-1:0] a, b, act;
  reg [MuBi20Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi20Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] && b[k]) : (a[k] || b[k]);
    end
    mubi20_and = out;
  end
endfunction

function automatic [MuBi20Width-1:0] mubi20_or_hi;
  input [MuBi20Width-1:0] a, b;
  begin
    mubi20_or_hi = mubi20_or(a, b, MuBi20True);
  end
endfunction

function automatic [MuBi20Width-1:0] mubi20_and_hi;
  input [MuBi20Width-1:0] a, b;
  begin
    mubi20_and_hi = mubi20_and(a, b, MuBi20True);
  end
endfunction

function automatic [MuBi20Width-1:0] mubi20_or_lo;
  input [MuBi20Width-1:0] a, b;
  begin
    mubi20_or_lo = mubi20_or(a, b, MuBi20False);
  end
endfunction

function automatic [MuBi20Width-1:0] mubi20_and_lo;
  input [MuBi20Width-1:0] a, b;
  begin
    mubi20_and_lo = mubi20_and(a, b, MuBi20False);
  end
endfunction


//--------------------------------------------------------------
// 24-Bit Multi-Bit (MuBi) Definitions
//--------------------------------------------------------------

localparam MuBi24Width = 24;
localparam [MuBi24Width-1:0] MuBi24True = 24'h969696;   // Enabled 
localparam [MuBi24Width-1:0] MuBi24False = 24'h696969;  // Disabled

initial begin
  if (MuBi24True !== ~MuBi24False) begin
    $display("ERROR: MuBi24True and MuBi24False are not complementary!");
    $finish;
  end
end

function automatic mubi24_test_invalid;
  input [MuBi24Width-1:0] val;
  begin
    mubi24_test_invalid = (val !== MuBi24True) && (val !== MuBi24False);
  end
endfunction

function automatic [MuBi24Width-1:0] mubi24_bool_to_mubi;
  input val;
  begin
    mubi24_bool_to_mubi = val ? MuBi24True : MuBi24False;
  end
endfunction

function automatic mubi24_test_true_strict;
  input [MuBi24Width-1:0] val;
  begin
    mubi24_test_true_strict = (val === MuBi24True);
  end
endfunction

function automatic mubi24_test_false_strict;
  input [MuBi24Width-1:0] val;
  begin
    mubi24_test_false_strict = (val === MuBi24False);
  end
endfunction

function automatic mubi24_test_true_loose;
  input [MuBi24Width-1:0] val;
  begin
    mubi24_test_true_loose = (val !== MuBi24False);
  end
endfunction

function automatic mubi24_test_false_loose;
  input [MuBi24Width-1:0] val;
  begin
    mubi24_test_false_loose = (val !== MuBi24True);
  end
endfunction

function automatic [MuBi24Width-1:0] mubi24_or;
  input [MuBi24Width-1:0] a, b, act;
  reg [MuBi24Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi24Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] || b[k]) : (a[k] && b[k]);
    end
    mubi24_or = out;
  end
endfunction

function automatic [MuBi24Width-1:0] mubi24_and;
  input [MuBi24Width-1:0] a, b, act;
  reg [MuBi24Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi24Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] && b[k]) : (a[k] || b[k]);
    end
    mubi24_and = out;
  end
endfunction

function automatic [MuBi24Width-1:0] mubi24_or_hi;
  input [MuBi24Width-1:0] a, b;
  begin
    mubi24_or_hi = mubi24_or(a, b, MuBi24True);
  end
endfunction

function automatic [MuBi24Width-1:0] mubi24_and_hi;
  input [MuBi24Width-1:0] a, b;
  begin
    mubi24_and_hi = mubi24_and(a, b, MuBi24True);
  end
endfunction

function automatic [MuBi24Width-1:0] mubi24_or_lo;
  input [MuBi24Width-1:0] a, b;
  begin
    mubi24_or_lo = mubi24_or(a, b, MuBi24False);
  end
endfunction

function automatic [MuBi24Width-1:0] mubi24_and_lo;
  input [MuBi24Width-1:0] a, b;
  begin
    mubi24_and_lo = mubi24_and(a, b, MuBi24False);
  end
endfunction


//--------------------------------------------------------------
// 28-Bit Multi-Bit (MuBi) Definitions
//--------------------------------------------------------------

localparam MuBi28Width = 28;
localparam [MuBi28Width-1:0] MuBi28True = 28'h6969696;   // Enabled 
localparam [MuBi28Width-1:0] MuBi28False = 28'h9696969;  // Disabled

initial begin
  if (MuBi28True !== ~MuBi28False) begin
    $display("ERROR: MuBi28True and MuBi28False are not complementary!");
    $finish;
  end
end

function automatic mubi28_test_invalid;
  input [MuBi28Width-1:0] val;
  begin
    mubi28_test_invalid = (val !== MuBi28True) && (val !== MuBi28False);
  end
endfunction

function automatic [MuBi28Width-1:0] mubi28_bool_to_mubi;
  input val;
  begin
    mubi28_bool_to_mubi = val ? MuBi28True : MuBi28False;
  end
endfunction

function automatic mubi28_test_true_strict;
  input [MuBi28Width-1:0] val;
  begin
    mubi28_test_true_strict = (val === MuBi28True);
  end
endfunction

function automatic mubi28_test_false_strict;
  input [MuBi28Width-1:0] val;
  begin
    mubi28_test_false_strict = (val === MuBi28False);
  end
endfunction

function automatic mubi28_test_true_loose;
  input [MuBi28Width-1:0] val;
  begin
    mubi28_test_true_loose = (val !== MuBi28False);
  end
endfunction

function automatic mubi28_test_false_loose;
  input [MuBi28Width-1:0] val;
  begin
    mubi28_test_false_loose = (val !== MuBi28True);
  end
endfunction

function automatic [MuBi28Width-1:0] mubi28_or;
  input [MuBi28Width-1:0] a, b, act;
  reg [MuBi28Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi28Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] || b[k]) : (a[k] && b[k]);
    end
    mubi28_or = out;
  end
endfunction

function automatic [MuBi28Width-1:0] mubi28_and;
  input [MuBi28Width-1:0] a, b, act;
  reg [MuBi28Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi28Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] && b[k]) : (a[k] || b[k]);
    end
    mubi28_and = out;
  end
endfunction

function automatic [MuBi28Width-1:0] mubi28_or_hi;
  input [MuBi28Width-1:0] a, b;
  begin
    mubi28_or_hi = mubi28_or(a, b, MuBi28True);
  end
endfunction

function automatic [MuBi28Width-1:0] mubi28_and_hi;
  input [MuBi28Width-1:0] a, b;
  begin
    mubi28_and_hi = mubi28_and(a, b, MuBi28True);
  end
endfunction

function automatic [MuBi28Width-1:0] mubi28_or_lo;
  input [MuBi28Width-1:0] a, b;
  begin
    mubi28_or_lo = mubi28_or(a, b, MuBi28False);
  end
endfunction

function automatic [MuBi28Width-1:0] mubi28_and_lo;
  input [MuBi28Width-1:0] a, b;
  begin
    mubi28_and_lo = mubi28_and(a, b, MuBi28False);
  end
endfunction


//--------------------------------------------------------------
// 32-Bit Multi-Bit (MuBi) Definitions
//--------------------------------------------------------------

localparam MuBi32Width = 32;
localparam [MuBi32Width-1:0] MuBi32True = 32'h96969696;   // Enabled 
localparam [MuBi32Width-1:0] MuBi32False = 32'h69696969;  // Disabled

initial begin
  if (MuBi32True !== ~MuBi32False) begin
    $display("ERROR: MuBi32True and MuBi32False are not complementary!");
    $finish;
  end
end

function automatic mubi32_test_invalid;
  input [MuBi32Width-1:0] val;
  begin
    mubi32_test_invalid = (val !== MuBi32True) && (val !== MuBi32False);
  end
endfunction

function automatic [MuBi32Width-1:0] mubi32_bool_to_mubi;
  input val;
  begin
    mubi32_bool_to_mubi = val ? MuBi32True : MuBi32False;
  end
endfunction

function automatic mubi32_test_true_strict;
  input [MuBi32Width-1:0] val;
  begin
    mubi32_test_true_strict = (val === MuBi32True);
  end
endfunction

function automatic mubi32_test_false_strict;
  input [MuBi32Width-1:0] val;
  begin
    mubi32_test_false_strict = (val === MuBi32False);
  end
endfunction

function automatic mubi32_test_true_loose;
  input [MuBi32Width-1:0] val;
  begin
    mubi32_test_true_loose = (val !== MuBi32False);
  end
endfunction

function automatic mubi32_test_false_loose;
  input [MuBi32Width-1:0] val;
  begin
    mubi32_test_false_loose = (val !== MuBi32True);
  end
endfunction

function automatic [MuBi32Width-1:0] mubi32_or;
  input [MuBi32Width-1:0] a, b, act;
  reg [MuBi32Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi32Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] || b[k]) : (a[k] && b[k]);
    end
    mubi32_or = out;
  end
endfunction

function automatic [MuBi32Width-1:0] mubi32_and;
  input [MuBi32Width-1:0] a, b, act;
  reg [MuBi32Width-1:0] out;
  integer k;
  begin
    for (k = 0; k < MuBi32Width; k = k + 1) begin
      out[k] = act[k] ? (a[k] && b[k]) : (a[k] || b[k]);
    end
    mubi32_and = out;
  end
endfunction

function automatic [MuBi32Width-1:0] mubi32_or_hi;
  input [MuBi32Width-1:0] a, b;
  begin
    mubi32_or_hi = mubi32_or(a, b, MuBi32True);
  end
endfunction

function automatic [MuBi32Width-1:0] mubi32_and_hi;
  input [MuBi32Width-1:0] a, b;
  begin
    mubi32_and_hi = mubi32_and(a, b, MuBi32True);
  end
endfunction

function automatic [MuBi32Width-1:0] mubi32_or_lo;
  input [MuBi32Width-1:0] a, b;
  begin
    mubi32_or_lo = mubi32_or(a, b, MuBi32False);
  end
endfunction

function automatic [MuBi32Width-1:0] mubi32_and_lo;
  input [MuBi32Width-1:0] a, b;
  begin
    mubi32_and_lo = mubi32_and(a, b, MuBi32False);
  end
endfunction

endmodule