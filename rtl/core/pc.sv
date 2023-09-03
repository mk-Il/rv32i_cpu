// Program counter (32-bit)

module PC (
  input  logic  [0:0] clk_in, rst_n,
  input  logic  [0:0] we, // write enable
  input  logic [31:0] pc_in,
  output logic [31:0] pc_out
  );

  always_ff @( posedge clk_in ) begin
    if      (!rst_n) pc_in <= 32'd0;
    else if (we)     pc_out <= pc_in;
  end

endmodule
