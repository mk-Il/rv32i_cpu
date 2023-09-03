// Pipeline register
// Memory - Write back

module PlReg_M2W (
  input  logic  [0:0] clk_in,
  input  logic [31:0] alu_out_m,
  input  logic [31:0] mem_rdata_m,
  input  logic [31:0] next_pc_m,
  input  logic  [4:0] rs1addr_m,
  input  logic  [0:0] regwe_m,
  input  logic  [1:0] wb_sel_m,
  input  logic  [4:0] rd_m,
  input  logic  [2:0] funct3_m,
  input  logic  [0:0] csrwe_m,
  input  logic [11:0] csraddr_m,
  input  logic [31:0] csrrdata_m,
  output logic [31:0] alu_out_w,
  output logic [31:0] mem_rdata_w,
  output logic [31:0] next_pc_w,
  output logic  [4:0] rs1addr_w,
  output logic  [0:0] regwe_w,
  output logic  [1:0] wb_sel_w,
  output logic  [4:0] rd_w,
  output logic  [2:0] funct3_w,
  output logic  [0:0] csrwe_w,
  output logic [11:0] csraddr_w,
  output logic [31:0] csrrdata_w
  );

  always_ff @( posedge clk_in ) begin
    alu_out_w  <= alu_out_m;
    next_pc_w  <= next_pc_m;
    rs1addr_w  <= rs1addr_m;
    regwe_w    <= regwe_m;
    wb_sel_w   <= wb_sel_m;
    rd_w       <= rd_m;
    funct3_w   <= funct3_m;
    csrwe_w    <= csrwe_m;
    csraddr_w  <= csraddr_m;
    csrrdata_w <= csrrdata_m;

    mem_rdata_w <= mem_rdata_m;
  end

endmodule
