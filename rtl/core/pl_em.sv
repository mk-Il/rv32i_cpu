// Pipeline register
// Execution - Memory

module PlReg_E2M (
  input  logic  [0:0] clk_in,
  input  logic [31:0] alu_out_e,
  input  logic [31:0] next_pc_e,
  input  logic  [4:0] rs1addr_e,
  input  logic [31:0] memwdata_e,
  input  logic  [4:0] rd_e,
  input  logic  [1:0] wb_sel_e,
  input  logic  [0:0] regwe_e,
  input  logic  [0:0] memwe_e,
  input  logic  [0:0] fence_e,
  input  logic  [2:0] funct3_e,
  input  logic  [0:0] csrwe_e,
  input  logic [11:0] csraddr_e,
  input  logic [31:0] csrrdata_e,
  output logic [31:0] alu_out_m,
  output logic [31:0] next_pc_m,
  output logic  [4:0] rs1addr_m,
  output logic [31:0] memwdata_m,
  output logic  [4:0] rd_m,
  output logic  [1:0] wb_sel_m,
  output logic  [0:0] regwe_m,
  output logic  [0:0] memwe_m,
  output logic  [0:0] fence_m,
  output logic  [2:0] funct3_m,
  output logic  [0:0] csrwe_m,
  output logic [11:0] csraddr_m,
  output logic [31:0] csrrdata_m
  );

  always_ff @( posedge clk_in ) begin
    alu_out_m  <= alu_out_e;
    next_pc_m  <= next_pc_e;
    rs1addr_m  <= rs1addr_e;
    memwdata_m <= memwdata_e;
    rd_m       <= rd_e;
    wb_sel_m   <= wb_sel_e;
    regwe_m    <= regwe_e;
    memwe_m    <= memwe_e;
    fence_m    <= fence_e;
    funct3_m   <= funct3_e;
    csrwe_m    <= csrwe_e;
    csraddr_m  <= csraddr_e;
    csrrdata_m <= csrrdata_e;
  end

endmodule
