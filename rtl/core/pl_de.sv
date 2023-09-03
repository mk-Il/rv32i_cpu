// Pipeline register
// Decode - Execution

module PlReg_D2E (
  input  logic  [0:0] clk_in,
  input  logic  [0:0] flush,

  input  logic [31:0] pc_d,
  input  logic [31:0] next_pc_d,
  input  logic [31:0] rs1_d,
  input  logic [31:0] rs2_d,
  input  logic  [4:0] rs1addr_d,
  input  logic  [4:0] rs2addr_d,
  input  logic [31:0] imm32_d,
  input  logic  [3:0] alu_ctrl_d,
  input  logic  [0:0] alu_sr1_sel_d,
  input  logic  [0:0] alu_sr2_sel_d,
  input  logic  [2:0] funct3_d,
  input  logic  [0:0] is_jump_d,
  input  logic  [0:0] is_branch_d,
  input  logic  [1:0] wb_sel_d,
  input  logic  [4:0] rd_d,
  input  logic  [0:0] regwe_d,
  input  logic  [0:0] memwe_d,
  input  logic  [0:0] fence_d,
  input  logic  [0:0] csrwe_d,
  input  logic [11:0] csraddr_d,
  input  logic [31:0] csrrdata_d,
  output logic [31:0] pc_e,
  output logic [31:0] next_pc_e,
  output logic [31:0] rs1_e,
  output logic [31:0] rs2_e,
  output logic  [4:0] rs1addr_e,
  output logic  [4:0] rs2addr_e,
  output logic [31:0] imm32_e,
  output logic  [3:0] alu_ctrl_e,
  output logic  [0:0] alu_sr1_sel_e,
  output logic  [0:0] alu_sr2_sel_e,
  output logic  [2:0] funct3_e,
  output logic  [0:0] is_jump_e,
  output logic  [0:0] is_branch_e,
  output logic  [1:0] wb_sel_e,
  output logic  [4:0] rd_e,
  output logic  [0:0] regwe_e,
  output logic  [0:0] memwe_e,
  output logic  [0:0] fence_e,
  output logic  [0:0] csrwe_e,
  output logic [11:0] csraddr_e,
  output logic [31:0] csrrdata_e
  );

  always_ff @( posedge clk_in ) begin
    pc_e          <= pc_d;
    next_pc_e     <= next_pc_d;
    rs1_e         <= rs1_d;
    rs2_e         <= rs2_d;
    rs1addr_e     <= rs1addr_d; // for register forwading
    rs2addr_e     <= rs2addr_d; // for register forwading
    imm32_e       <= imm32_d;
    alu_ctrl_e    <= alu_ctrl_d;
    alu_sr1_sel_e <= alu_sr1_sel_d;
    alu_sr2_sel_e <= alu_sr2_sel_d;
    funct3_e      <= funct3_d;
    wb_sel_e      <= wb_sel_d;
    fence_e       <= fence_d;
    is_jump_e     <= flush ? 1'b0 : is_jump_d;
    is_branch_e   <= flush ? 1'b0 : is_branch_d;
    rd_e          <= flush ? 5'b0 : rd_d;
    regwe_e       <= flush ? 1'b0 : regwe_d;
    memwe_e       <= flush ? 1'b0 : memwe_d;
    csrwe_e       <= flush ? 1'b0 : csrwe_d;
    csraddr_e     <= csraddr_d;
    csrrdata_e    <= csrrdata_d;
  end

endmodule
