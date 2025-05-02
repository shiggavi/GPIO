module prim_filter_ctr #(
  // Parameters
  parameter bit AsyncOn = 0,            // If set, adds a 2-stage synchronizer to input
  parameter int unsigned CntWidth = 2   // Width of stability counter (default 2 bits)
) (
  input                clk_i,           // Clock input
  input                rst_ni,          // Active-low reset input
  input                enable_i,        // Enable signal for filtering
  input                filter_i,        // Raw (possibly noisy) input signal
  input [CntWidth-1:0] thresh_i,         // Threshold: number of stable cycles required
  output wire         filter_o          // Filtered output signal
);

  // Internal signals
  reg [CntWidth-1:0] diff_ctr_q, 
  wire [CntWidth-1:0] diff_ctr_d;  // Stability counter (current and next values)
  reg filter_q;                              // Last sampled input value
  reg stored_value_q;                        // Stored filtered output value
  wire update_stored_value;                   // Flag to update filtered output

  wire filter_synced;                         // Synchronized (de-metastabilized) input

  //-------------------------------------------------------------------------
  // Synchronize input if AsyncOn parameter is set
  //-------------------------------------------------------------------------
  generate 
        if (AsyncOn) begin : gen_async
            // Use a 2-stage flop synchronizer to prevent metastability
            prim_flop_2sync #(
            .Width(1)
            ) prim_flop_2sync ( 
            .clk_i,
            .rst_ni,
            .d_i(filter_i),
            .q_o(filter_synced)
            );
        end else begin : gen_sync
            // No synchronization needed, pass input directly
            assign filter_synced = filter_i;
        end
  endgenerate
  //-------------------------------------------------------------------------
  // Sample the current input every clock cycle
  //-------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      filter_q <= 1'b0; // On reset, initialize sampled input to 0
    end else begin
      filter_q <= filter_synced; // Otherwise, capture current synchronized input
    end
  end

  //-------------------------------------------------------------------------
  // Update stored (filtered) output value when input has been stable long enough
  //-------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      stored_value_q <= 1'b0; // On reset, clear stored output
    end else if (update_stored_value) begin
      stored_value_q <= filter_synced; // Update stored value if input stable for threshold cycles
    end
  end

  //-------------------------------------------------------------------------
  // Stability counter logic
  //-------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      diff_ctr_q <= '0; // On reset, clear counter
    end else begin
      diff_ctr_q <= diff_ctr_d; // Update counter to next value
    end
  end

  //-------------------------------------------------------------------------
  // Counter Update Logic
  //-------------------------------------------------------------------------
  // If current input is different from previous sampled input:
  // - Reset counter to 0 (input not stable yet)
  // Else:
  // - If counter already reached threshold, saturate at threshold
  // - Otherwise, increment counter
  assign diff_ctr_d = (filter_synced != filter_q) ? '0 : 
                      (diff_ctr_q >= thresh_i)    ? thresh_i : 
                      (diff_ctr_q + 1'b1);

  //-------------------------------------------------------------------------
  // Generate flag to update stored value
  //-------------------------------------------------------------------------
  // If counter reaches threshold, allow updating filtered output
  assign update_stored_value = (diff_ctr_d == thresh_i);

  //-------------------------------------------------------------------------
  // Final Output Mux
  //-------------------------------------------------------------------------
  // If filtering is enabled (enable_i == 1):
  // - Output the stored (filtered) value
  // Else:
  // - Bypass and output the raw synchronized input directly
  assign filter_o = enable_i ? stored_value_q : filter_synced;

endmodule
