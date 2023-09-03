// Control unit


// opcodes
`define LOAD      7'b0000011
`define OP_IMM    7'b0010011
`define OP        7'b0110011
`define STORE     7'b0100011
`define BRANCH    7'b1100011
`define LUI       7'b0110111
`define AUIPC     7'b0010111
`define JAL       7'b1101111
`define JALR      7'b1100111
`define MISC_MEM  7'b0001111
`define SYSTEM    7'b1110011


module ControlUnit (
  input  logic [31:0] inst,

  output logic  [5:0] inst_type,   // one hot (I/J/U/B/S/R), to ImmExt32
  output logic  [3:0] alu_ctrl,
  output logic  [1:0] wb_sel,      // Write back data selector, 00:alu, 01:mem, 10:pc+4, 11:csr
  output logic  [0:0] alu_sr1_sel, // ALU source 1 selector. 0: rs1, 1: pc
  output logic  [0:0] alu_sr2_sel, // ALU source 2 selector. 0: rs2, 1: imm
  output logic  [0:0] reg_we,      // Write enable for regfile
  output logic  [0:0] mem_we,      // Write enable for data memory
  output logic  [0:0] is_jump,
  output logic  [2:0] funct3,
  output logic  [4:0] rs1, rs2, rd,
  output logic  [0:0] fence,
  output logic  [0:0] csr_we,      // CSR write enable
  output logic [11:0] csr_addr,    // CSR 12-bit address (r/w)
  output logic [15:0] exp_code,
  output logic  [0:0] is_mret,
  output logic  [0:0] is_wfi
  );

  // ---------------------------------
  // Decode instruction
  // ---------------------------------
  logic  [6:0] opcode, funct7;
  assign {funct7, rs2, rs1, funct3, rd, opcode} = inst;

  // ---------------------------------
  // Get instruction type
  // ---------------------------------
  struct packed {
    logic [0:0] F, SY, L, SI, I, J, U, B, S, R;
  } i; // Instruction type

  assign i.R  = (opcode == `OP);                            // R-type
  assign i.S  = (opcode == `STORE);                         // S-type
  assign i.B  = (opcode == `BRANCH);                        // B-type
  assign i.J  = (opcode == `JAL);                           // J-type
  assign i.U  = opcode inside {`LUI, `AUIPC};               // U-type
  assign i.I  = opcode inside {`OP_IMM, `JALR, `LOAD};      // I-type
  assign i.L  = (opcode == `LOAD);                          // LOAD type
  assign i.SI = (opcode == `OP_IMM) && (funct3 ==? 3'b?01); // Shift with immediate type(SLLI, SRLI, SRAI)
  assign i.SY = (opcode == `SYSTEM);                        // SYSTEM type (CSR, etc.)
  assign i.F  = (opcode == `MISC_MEM);                      // fence, fence.i

  assign inst_type = i[5:0]; // one hot (I/J/U/B/S/R)

  // ---------------------------------
  // Exception
  // ---------------------------------
  wire [0:0] illegal_op = ~|i;
  wire [0:0] ecall  = i.SY && ({funct7, rs2, rs1, funct3, rd} == '0);
  wire [0:0] ebreak = i.SY && ({funct7, rs1, funct3, rd} == '0) && (rs2 == 5'b1);

  assign exp_code = {4'b0, ecall, 7'b0, ebreak, illegal_op, 2'b0};

  // ---------------------------------
  // ALU decoder
  // ---------------------------------
  always_comb begin
    if      (opcode == `LUI) alu_ctrl = 4'b1111;
    else if (i.R || i.SI)    alu_ctrl = {funct3,funct7[5]};
    else if (i.I && !i.L)    alu_ctrl = {funct3,1'b0};
    else if (i.SY)           alu_ctrl = 4'b1101;
    else                     alu_ctrl = 4'b0;
  end

  // ---------------------------------
  // Outputs
  // ---------------------------------
  assign alu_sr1_sel = i.J || i.B || i.U; // 0: rs1, 1: pc
  assign alu_sr2_sel = !i.R;              // 0: rs2, 1: imm
  assign reg_we      = i.R || i.I || i.U || i.J || csr_we;
  assign mem_we      = i.S;
  assign is_jump     = i.J || (opcode == `JALR);
  assign wb_sel      = {is_jump, i.L} | {2{csr_we}};
  assign fence       = i.F;
  // csr
  assign csr_we      = i.SY && (funct3 != 3'b0);
  assign csr_addr    = {funct7, rs2};
  assign is_mret     = i.SY && (funct3 == 3'b0) && (csr_addr == 12'h302);
  assign is_wfi      = i.SY && (funct3 == 3'b0) && (csr_addr == 12'h105);

endmodule
