// RV32I CPU core
// 5-stage pipeline (Fetch, Decode, Execute, Memory, Write back)


module RV32I_core (
  input  logic  [0:0] clk_in, rst_n,
  input  logic  [0:0] ext_irq,    // external interrupt request
  input  logic  [0:0] timer_irq,  // timer interrupt
  input  logic  [0:0] sw_irq,     // software interrupt
  input  logic [31:0] imem_rdata, // instruction data
  input  logic [31:0] dbus_rdata,

  output logic  [3:0] dbus_we,    // byte write enable
  output logic [31:0] imem_addr,
  output logic [31:0] dbus_addr,
  output logic [31:0] dbus_wdata
  );

  // ---------------------------------
  // Wires
  // ---------------------------------
  logic  [0:0] ctrl_alusr1_o; // ALU source 1 selector. 0: regfile, 1: pc
  logic  [0:0] ctrl_alusr2_o; // ALU source 2 selector. 0: regfile, 1: imm
  logic  [0:0] ctrl_isjump_o;
  logic  [0:0] ctrl_regwe_o;  // Write enable for register file
  logic  [0:0] ctrl_dmemwe_o; // Write enable for memory
  logic  [1:0] ctrl_wbsel_o;  // 00:alu, 01:mem, 10:pc+4, 11:csr
  logic  [4:0] ctrl_rs1_o, ctrl_rs2_o, ctrl_rd_o;
  logic  [2:0] ctrl_funct3_o;
  logic  [3:0] ctrl_aluctrl_o;
  logic  [5:0] ctrl_itype_o;
  logic [11:0] ctrl_csraddr_o;
  logic  [0:0] ctrl_csrwe_o;
  logic  [0:0] ctrl_fence_o;
  logic  [0:0] ctrl_ismret_o;
  logic  [0:0] ctrl_iswfi_o;
  logic [15:0] ctrl_expcode_o;
  logic [31:0] signimm32_o;
  logic [31:0] reg_rs1_o, reg_rs2_o;
  logic [31:0] alu_result_o;
  logic  [0:0] br_taken_o;
  logic [31:0] pc_o;
  logic  [2:0] fwd_sr1_e, fwd_sr2_e;
  logic  [0:0] fence_e, fence_m;
  logic  [0:0] stall_o;
  // csr
  logic  [0:0] csr_interrupt_o;
  logic [31:0] csr_rdata_o, csr_mtvec_o;
  // lsu
  logic  [3:0] lsu_we4_o;
  logic [31:0] lsu_din2mem_o, lsu_dout2cpu_o;
  // pipeline registers
  logic [31:0] inst_d;
  logic [31:0] pc_d, pc_e;
  logic [31:0] next_pc_d, next_pc_e, next_pc_m, next_pc_w;
  logic  [4:0] rs1addr_e, rs1addr_m, rs1addr_w;
  logic [31:0] imm32_e;
  logic  [4:0] rs2addr_e;
  logic  [3:0] alu_ctrl_e;
  logic  [0:0] alu_sr1_sel_e;
  logic  [0:0] alu_sr2_sel_e;
  logic  [0:0] is_branch_e;
  logic  [0:0] is_jump_e;
  logic  [2:0] funct3_e, funct3_m, funct3_w;
  logic  [0:0] memwe_e, memwe_m;
  logic  [1:0] wb_sel_e, wb_sel_m, wb_sel_w;
  logic  [4:0] rd_e, rd_m, rd_w;
  logic  [0:0] regwe_e, regwe_m, regwe_w;
  logic  [0:0] csrwe_e, csrwe_m, csrwe_w;
  logic [11:0] csraddr_e, csraddr_m, csraddr_w;
  logic [31:0] csrrdata_e, csrrdata_m, csrrdata_w;
  logic [31:0] rs1_e;
  logic [31:0] rs2_e, rs2_m;
  logic [31:0] alu_out_m, alu_out_w;
  logic [31:0] mem_rdata_w;

  wire [31:0] next_pc = pc_o + 32'd4;

  // ---------------------------------
  // Data selectors
  // ---------------------------------
  // select data to write back in rd
  logic [31:0] mux4_wbsel_o;
  always_comb begin
    case (wb_sel_w)
      2'b00:   mux4_wbsel_o = alu_out_w;
      2'b01:   mux4_wbsel_o = mem_rdata_w;
      2'b10:   mux4_wbsel_o = next_pc_w;
      2'b11:   mux4_wbsel_o = csrrdata_w;
    endcase
  end

  // forwading logic (mem/wb -> exe)
  logic [31:0] mux5_fwdsr1_o, mux5_fwdsr2_o;
  always_comb begin
    case (fwd_sr1_e)
      3'b000:  mux5_fwdsr1_o = rs1_e;
      3'b001:  mux5_fwdsr1_o = mux4_wbsel_o;
      3'b010:  mux5_fwdsr1_o = alu_out_m;
      3'b100:  mux5_fwdsr1_o = csrrdata_m;
      3'b101:  mux5_fwdsr1_o = csrrdata_w;
      default: mux5_fwdsr1_o = rs1_e;
    endcase
  end
  always_comb begin
    case (fwd_sr2_e)
      3'b000:  mux5_fwdsr2_o = rs2_e;
      3'b001:  mux5_fwdsr2_o = mux4_wbsel_o;
      3'b010:  mux5_fwdsr2_o = alu_out_m;
      3'b100:  mux5_fwdsr2_o = csrrdata_m;
      3'b101:  mux5_fwdsr2_o = csrrdata_w;
      default: mux5_fwdsr2_o = rs2_e;
    endcase
  end

  // PC source selector
  wire [0:0] pcsrc_e = is_jump_e || (is_branch_e && br_taken_o); // 0: pc+4, 1: alu_out

  logic [31:0] mux4_pcsrc_o;
  always_comb begin
    if (ctrl_ismret_o)
        mux4_pcsrc_o = csr_rdata_o; // mepc
    else if (csr_interrupt_o || (|ctrl_expcode_o))
        mux4_pcsrc_o = csr_mtvec_o;
    else if (pcsrc_e)
        mux4_pcsrc_o = alu_result_o;
    else
        mux4_pcsrc_o = next_pc;
  end
  
  // ALU source selector
  wire [31:0] mux2_alusr1_o = alu_sr1_sel_e ? pc_e    : mux5_fwdsr1_o; // select pc(1) or rs1(0)
  wire [31:0] mux2_alusr2_o = alu_sr2_sel_e ? imm32_e : mux5_fwdsr2_o; // select imm32(1) or rs2(0)
  
  // ---------------------------------
  // Submodules
  // ---------------------------------
  // Pipeline control
  ForwardingUnit fwdunit (
    // in
    .rs1addr_e (rs1addr_e),
    .rs2addr_e (rs2addr_e),
    .rd_m      (rd_m),
    .rd_w      (rd_w),
    .regwe_m   (regwe_m),
    .regwe_w   (regwe_w),
    .csrwe_m   (csrwe_m),
    .csrwe_w   (csrwe_w),
    // out
    .fwd_sr1_e (fwd_sr1_e),
    .fwd_sr2_e (fwd_sr2_e)
  );
  
  HazardUnit hzdunit (
    // in
    .rs1addr_d (ctrl_rs1_o),
    .rs2addr_d (ctrl_rs2_o),
    .rd_e      (rd_e),
    .is_load_e (wb_sel_e == 2'b01),
    .fence_d   (ctrl_fence_o),
    .fence_m   (fence_m),
    // out
    .stall     (stall_o)
  );

  // Pipeline registers
  wire [0:0] wfi_status = ctrl_iswfi_o && !csr_interrupt_o;
  wire [0:0] fd_flush = ctrl_isjump_o || pcsrc_e || csr_interrupt_o || (|ctrl_expcode_o) || ctrl_ismret_o;
  PlReg_F2D FD_reg (
    .clk_in, .rst_n,
    .we (!stall_o && !wfi_status),
    .flush (fd_flush),
    // in                    out
    .pc_f      (pc_o),       .pc_d      (pc_d),
    .next_pc_f (next_pc),    .next_pc_d (next_pc_d),
    .inst_f    (imem_rdata), .inst_d    (inst_d)
  );

  wire [0:0] de_flush = stall_o || pcsrc_e || csr_interrupt_o;
  PlReg_D2E DE_reg (
    .clk_in,
    .flush (de_flush),
    // in                             out
    .pc_d          (pc_d),            .pc_e          (pc_e),
    .next_pc_d     (next_pc_d),       .next_pc_e     (next_pc_e),
    .rs1_d         (reg_rs1_o),       .rs1_e         (rs1_e),
    .rs2_d         (reg_rs2_o),       .rs2_e         (rs2_e),
    .rs1addr_d     (ctrl_rs1_o),      .rs1addr_e     (rs1addr_e),
    .rs2addr_d     (ctrl_rs2_o),      .rs2addr_e     (rs2addr_e),
    .imm32_d       (signimm32_o),     .imm32_e       (imm32_e),
    .alu_ctrl_d    (ctrl_aluctrl_o),  .alu_ctrl_e    (alu_ctrl_e),
    .alu_sr1_sel_d (ctrl_alusr1_o),   .alu_sr1_sel_e (alu_sr1_sel_e),
    .alu_sr2_sel_d (ctrl_alusr2_o),   .alu_sr2_sel_e (alu_sr2_sel_e),
    .funct3_d      (ctrl_funct3_o),   .funct3_e      (funct3_e),
    .is_jump_d     (ctrl_isjump_o),   .is_jump_e     (is_jump_e),
    .is_branch_d   (ctrl_itype_o[2]), .is_branch_e   (is_branch_e),
    .wb_sel_d      (ctrl_wbsel_o),    .wb_sel_e      (wb_sel_e),
    .rd_d          (ctrl_rd_o),       .rd_e          (rd_e),
    .regwe_d       (ctrl_regwe_o),    .regwe_e       (regwe_e),
    .memwe_d       (ctrl_dmemwe_o),   .memwe_e       (memwe_e),
    .fence_d       (ctrl_fence_o),    .fence_e       (fence_e),
    .csrwe_d       (ctrl_csrwe_o),    .csrwe_e       (csrwe_e),
    .csraddr_d     (ctrl_csraddr_o),  .csraddr_e     (csraddr_e),
    .csrrdata_d    (csr_rdata_o),     .csrrdata_e    (csrrdata_e)
  );

  PlReg_E2M EM_reg (
    .clk_in,
    // in                        out
    .alu_out_e  (alu_result_o),  .alu_out_m  (alu_out_m),
    .next_pc_e  (next_pc_e),     .next_pc_m  (next_pc_m),
    .rs1addr_e  (rs1addr_e),     .rs1addr_m  (rs1addr_m),
    .memwdata_e (mux5_fwdsr2_o), .memwdata_m (rs2_m),
    .rd_e       (rd_e),          .rd_m       (rd_m),
    .wb_sel_e   (wb_sel_e),      .wb_sel_m   (wb_sel_m),
    .regwe_e    (regwe_e),       .regwe_m    (regwe_m),
    .memwe_e    (memwe_e),       .memwe_m    (memwe_m),
    .fence_e    (fence_e),       .fence_m    (fence_m),
    .funct3_e   (funct3_e),      .funct3_m   (funct3_m),
    .csrwe_e    (csrwe_e),       .csrwe_m    (csrwe_m),
    .csraddr_e  (csraddr_e),     .csraddr_m  (csraddr_m),
    .csrrdata_e (csrrdata_e),    .csrrdata_m (csrrdata_m)
  );

  PlReg_M2W MW_reg (
    .clk_in,
    // in                          out
    .alu_out_m   (alu_out_m),      .alu_out_w   (alu_out_w),
    .mem_rdata_m (lsu_dout2cpu_o), .mem_rdata_w (mem_rdata_w),
    .next_pc_m   (next_pc_m),      .next_pc_w   (next_pc_w),
    .rs1addr_m   (rs1addr_m),      .rs1addr_w   (rs1addr_w),
    .regwe_m     (regwe_m),        .regwe_w     (regwe_w),
    .wb_sel_m    (wb_sel_m),       .wb_sel_w    (wb_sel_w),
    .rd_m        (rd_m),           .rd_w        (rd_w),
    .funct3_m    (funct3_m),       .funct3_w    (funct3_w),
    .csrwe_m     (csrwe_m),        .csrwe_w     (csrwe_w),
    .csraddr_m   (csraddr_m),      .csraddr_w   (csraddr_w),
    .csrrdata_m  (csrrdata_m),     .csrrdata_w  (csrrdata_w)
  );

  // Main components
  PC pc (
    // in
    .clk_in, .rst_n,
    .we     (!stall_o && !wfi_status),
    .pc_in  (mux4_pcsrc_o),
    // out
    .pc_out (pc_o)
  );

  Regfile regfile (
    // in
    .clk_in,
    .we      (regwe_w),
    .waddr   (rd_w),
    .wdata   (mux4_wbsel_o),
    .rs1addr (ctrl_rs1_o),
    .rs2addr (ctrl_rs2_o),
    // out
    .rs1     (reg_rs1_o),
    .rs2     (reg_rs2_o)
  );

  ALU alu (
    // in
    .ctrl (alu_ctrl_e),
    .sr1  (mux2_alusr1_o),
    .sr2  (mux2_alusr2_o),
    // out
    .out  (alu_result_o)
  );

  BranchComp bcomp (
    // in
    .rs1      (mux5_fwdsr1_o),
    .rs2      (mux5_fwdsr2_o),
    .funct3   (funct3_e),
    // out
    .br_taken (br_taken_o)
  );

  ImmExt32 immext (
    // in
    .inst_type (ctrl_itype_o),
    .inst25    (inst_d[31:7]),
    // out
    .signimm32 (signimm32_o)
  );

  ControlUnit ctrlunit (
    // in
    .inst        (inst_d),
    // out
    .inst_type   (ctrl_itype_o),
    .alu_ctrl    (ctrl_aluctrl_o),
    .alu_sr1_sel (ctrl_alusr1_o),
    .alu_sr2_sel (ctrl_alusr2_o),
    .is_jump     (ctrl_isjump_o),
    .reg_we      (ctrl_regwe_o),
    .mem_we      (ctrl_dmemwe_o),
    .wb_sel      (ctrl_wbsel_o),
    .funct3      (ctrl_funct3_o),
    .rs1         (ctrl_rs1_o),
    .rs2         (ctrl_rs2_o),
    .rd          (ctrl_rd_o),
    .fence       (ctrl_fence_o),
    .csr_we      (ctrl_csrwe_o),
    .csr_addr    (ctrl_csraddr_o),
    .exp_code    (ctrl_expcode_o),
    .is_mret     (ctrl_ismret_o),
    .is_wfi      (ctrl_iswfi_o)
  );

  CSR csr (
    // in
    .clk_in, .rst_n,
    .retire      (!stall_o), // !(fd_flush || stall_o)
    .exception   (|ctrl_expcode_o),
    .exp_code    (ctrl_expcode_o),
    .inst        (inst_d),
    .ext_irq     (ext_irq),
    .timer_irq   (timer_irq),
    .sw_irq      (sw_irq),
    .is_mret     (ctrl_ismret_o),
    .epc         (pc_d),
    .csr_we      (csrwe_w),
    .csr_funct3  (funct3_w),
    .csr_zimm    (rs1addr_w),
    .csr_rdata_w (mux4_wbsel_o), // csrrdata_w
    .csr_waddr   (csraddr_w),
    .csr_wdata   (alu_out_w),
    .csr_raddr   (ctrl_csraddr_o),
    // out
    .csr_rdata   (csr_rdata_o),
    .interrupt   (csr_interrupt_o),
    .mtvec_out   (csr_mtvec_o)
  );

  LoadStoreUnit lsu (
    // in
    .we          (memwe_m),
    .wmode       (funct3_m[1:0]),
    .rmode       (funct3_m),
    .addr_offset (alu_out_m[1:0]),
    .din_cpu     (rs2_m),
    .dout_mem    (dbus_rdata),
    // out
    .we4         (lsu_we4_o),
    .dout2cpu    (lsu_dout2cpu_o),
    .din2mem     (lsu_din2mem_o)
  );

  // ---------------------------------
  // Outputs
  // ---------------------------------
  assign imem_addr  = pc_o;
  assign dbus_we    = lsu_we4_o;
  assign dbus_addr  = alu_out_m;
  assign dbus_wdata = lsu_din2mem_o;

endmodule
