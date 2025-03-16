module debounce (
    input  trig,
    input  clk,
    output out
);

  // Trigger debounce logic
  logic trigger_prev = 0;  // Previous state of trigger signal
  logic out = 0;  // Flag for rising edge detection

  // Debouncing the trigger to detect rising edge
  always_ff @(posedge clk) begin
    trigger_prev <= trig;
    out <= trig && !trigger_prev;  // Detect rising edge (trigger asserted)
  end
endmodule
