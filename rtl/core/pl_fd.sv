// Pipeline register
// Instruction Fetch - Decode

module PlReg_F2D (
  input  logic  [0:0] clk_in, rst_n,
  input  logic  [0:0] we,
  input  logic  [0:0] flush,
  input  logic [31:0] pc_f,
  input  logic [31:0] next_pc_f,
  input  logic [31:0] inst_f,
  output logic [31:0] pc_d,
  output logic [31:0] next_pc_d,
  output logic [31:0] inst_d
  );

  localparam nop = 32'h0000_0013;
  //wire [31:0] inst = (flush || inst_f == '0) ? nop : inst_f;

  always_ff @( posedge clk_in ) begin
    if (!rst_n) begin
        pc_d      <= '0;
        next_pc_d <= '0;
        inst_d    <= nop;
    end else if (flush) begin
        inst_d    <= nop;
    end else if (we) begin
        pc_d      <= pc_f;
        next_pc_d <= next_pc_f;
        inst_d    <= inst_f;
    end
  end

endmodule
