// CSR (Control & Status Registers) module


module CSR #(
  parameter HARTID = 0
  )(
  input  logic  [0:0] clk_in, rst_n,
  input  logic  [0:0] retire,     // for minstret
  input  logic  [0:0] exception,
  input  logic [15:0] exp_code,
  input  logic [31:0] inst,
  input  logic  [0:0] ext_irq,    // external interrupt request
  input  logic  [0:0] timer_irq,  // timer interrupt
  input  logic  [0:0] sw_irq,     // software interrupt
  input  logic  [0:0] is_mret,
  input  logic [31:0] epc,        // pc where the exception occurred
  input  logic  [0:0] csr_we,     // write enable
  input  logic  [2:0] csr_funct3,
  input  logic  [4:0] csr_zimm,
  input  logic [31:0] csr_rdata_w,
  input  logic [11:0] csr_waddr,
  input  logic [31:0] csr_wdata,  // = rs1
  input  logic [11:0] csr_raddr,
  output logic [31:0] csr_rdata,
  output logic  [0:0] interrupt,
  output logic [31:0] mtvec_out
  );

  logic [31:0] mstatus;
  logic [31:0] misa;
  logic [31:0] medeleg;
  logic [31:0] mideleg;
  logic [31:0] mie;
  logic [31:0] mtvec;
  logic [31:0] mscratch;
  logic [31:0] mepc;
  logic [31:0] mcause;
  logic [31:0] mtval;
  logic [31:0] mip;
  logic [63:0] mcycle;
  logic [63:0] minstret;

  // -----------------------------------------------
  // Read logic
  // -----------------------------------------------
  always_comb begin
    case (csr_raddr)
      // machine trap setup
      12'h300: csr_rdata = mstatus;
      12'h301: csr_rdata = misa;
      12'h302: csr_rdata = is_mret ? mepc : medeleg;
      12'h303: csr_rdata = mideleg;
      12'h304: csr_rdata = mie;
      12'h305: csr_rdata = mtvec;
      12'h340: csr_rdata = mscratch;
      12'h341: csr_rdata = mepc;
      12'h342: csr_rdata = mcause;
      12'h343: csr_rdata = mtval;
      12'h344: csr_rdata = mip;
      // counter
      12'hb00: csr_rdata = mcycle[31:0];
      12'hb02: csr_rdata = minstret[31:0];
      12'hb80: csr_rdata = mcycle[63:32];
      12'hb82: csr_rdata = minstret[63:32];
      12'hc00: csr_rdata = mcycle[31:0];    // cycle
      12'hc02: csr_rdata = minstret[31:0];  // instret
      12'hc80: csr_rdata = mcycle[63:32];   // cycleh
      12'hc82: csr_rdata = minstret[63:32]; // instreth
      // machine information registers (read only)
      12'hf11: csr_rdata = '0;     // mvendorid
      12'hf12: csr_rdata = '0;     // marchid
      12'hf13: csr_rdata = '0;     // mimpid
      12'hf14: csr_rdata = HARTID; // mhartid
      default: csr_rdata = '0;
    endcase
  end // always_comb

  // -----------------------------------------------
  // Generate data to write
  // -----------------------------------------------
  logic [31:0] wdata_tmp;
  always_comb begin
    case (csr_funct3)
      3'b001:  wdata_tmp = csr_wdata;                     // csrrw
      3'b010:  wdata_tmp = csr_rdata_w | csr_wdata;       // csrrs
      3'b011:  wdata_tmp = csr_rdata_w & ~csr_wdata;      // csrrc
      3'b101:  wdata_tmp = {csr_rdata_w[31:5], csr_zimm}; // csrrwi
      3'b110:  wdata_tmp = csr_rdata_w | csr_zimm;        // csrrsi
      3'b111:  wdata_tmp = csr_rdata_w & ~csr_zimm;       // csrrci
      default: wdata_tmp = csr_wdata;
    endcase
  end

  // -----------------------------------------------
  // Machine Trap Setup
  // -----------------------------------------------
  wire [0:0] sw_int_out    = mstatus[3] && mie[3]  && mip[3];
  wire [0:0] timer_int_out = mstatus[3] && mie[7]  && mip[7];
  wire [0:0] ext_int_out   = mstatus[3] && mie[11] && mip[11];
  assign interrupt = sw_int_out || timer_int_out || ext_int_out;

  // mstatus(0x300) --------------------------------
  always_ff @( negedge clk_in ) begin
    if (!rst_n) begin
        mstatus <= {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, 1'b1, 3'b0}; // <= '0;
    end else if (is_mret) begin
        mstatus[12:11] <= 2'b11; // 2'b01(supervisor mode)
        mstatus[7]     <= 1'b1;
        mstatus[3]     <= mstatus[7];
    end else if (interrupt) begin
        mstatus[12:11] <= 2'b11;      // Machine mode
        mstatus[7]     <= mstatus[3]; // save previous MIE value to MPIE
        mstatus[3]     <= 1'b0;       // clear MIE (disable interrupt)
    end else if (csr_we && (csr_waddr == 12'h300)) begin
        mstatus <= wdata_tmp;
    end
  end

  // misa(0x301) -----------------------------------
  always_ff @( negedge clk_in ) begin
    if (!rst_n)
        misa <= {2'b01, 4'b0, 26'b100000000};
    else if (csr_we && (csr_waddr == 12'h301))
        misa <= wdata_tmp;
  end

  // medeleg(0x302) --------------------------------
  always_ff @( negedge clk_in ) begin
    if (!rst_n)
        medeleg <= '0;
    else if (csr_we && (csr_waddr == 12'h302))
        medeleg <= wdata_tmp;
  end

  // mideleg(0x303) --------------------------------
  always_ff @( negedge clk_in ) begin
    if (!rst_n)
        mideleg <= '0;
    else if (csr_we && (csr_waddr == 12'h303))
        mideleg <= wdata_tmp;
  end

  // mie(12'h304) ----------------------------------
  always_ff @( negedge clk_in ) begin
    if (!rst_n) begin
        mie <= '0;
    end else if (csr_we && (csr_waddr == 12'h304)) begin
        mie[11] <= wdata_tmp[11]; // meie (Machine-mode Exception Interrupt Enable)
        mie[7]  <= wdata_tmp[7];  // mtie (Machine-mode Timer Interrupt Enable)
        mie[3]  <= wdata_tmp[3];  // msie (M-mode Software Interrupt Enable)
    end
  end
  
  // mtvec(12'h305) --------------------------------
  always_ff @( negedge clk_in ) begin
    if (!rst_n)
        mtvec <= '0;
    else if (csr_we && (csr_waddr == 12'h305))
        mtvec <= wdata_tmp;
  end
  wire [1:0] mtvec_mode = mtvec[1:0];
  assign mtvec_out = mtvec_mode == 2'b01 ? (mtvec + (mcause<<2)) : mtvec;

  // mscratch(12'h340) -----------------------------
  always_ff @( negedge clk_in ) begin
    if (!rst_n)
        mscratch <= '0;
    else if (csr_we && (csr_waddr == 12'h340))
        mscratch <= wdata_tmp;
  end

  // mepc(12'h341) ---------------------------------
  always_ff @( negedge clk_in ) begin
    if (!rst_n)
        mepc <= '0;
    else if (exception)
        mepc <= epc;
    else if (interrupt)
        mepc <= epc + 32'd4;
    else if (csr_we && (csr_waddr == 12'h341))
        mepc <= wdata_tmp;
  end

  // mcause(12'h342) -------------------------------
  always_ff @( negedge clk_in ) begin
    if (!rst_n) begin
        mcause <= '0;
    end else if (exception) begin
        if      (exp_code[2])  mcause[15:0] <= 32'd2;  // illegal opcode
        else if (exp_code[3])  mcause[15:0] <= 32'd3;  // ebreak
        else if (exp_code[11]) mcause[15:0] <= 32'd11; // ecall
    end else if (interrupt) begin
        if      (sw_int_out)    mcause <= 32'd3  | (1<<31);
        else if (timer_int_out) mcause <= 32'd7  | (1<<31);
        else if (ext_int_out)   mcause <= 32'd11 | (1<<31);
    end else if (csr_we && (csr_waddr == 12'h342)) begin
        mcause <= wdata_tmp;
    end
  end

  // mtval(0x343) ----------------------------------
  always_ff @( negedge clk_in ) begin
    if (!rst_n) begin
        mtval <= '0;
    end else if (exception) begin
        if (exp_code[2]) mtval <= inst; // illegal op
    end
    //else if (interrupt)
    else if (csr_we && (csr_waddr == 12'h343)) begin
        mtval <= wdata_tmp;
    end
  end

  // mip(12'h344) ----------------------------------
  always_ff @( negedge clk_in ) begin
    if (!rst_n) begin
        mip <= '0;
    end else if (csr_we && (csr_waddr == 12'h344)) begin
        mip <= wdata_tmp;
    end else begin
        mip[11] <= ext_irq;   // meip //if (ext_irq)   mip[11] <= 1'b1;
        mip[7]  <= timer_irq; // mtip //if (timer_irq) mip[7]  <= 1'b1;
        mip[3]  <= sw_irq;    // msip //if (sw_irq)    mip[3]  <= 1'b1;
    end
  end

  // -----------------------------------------------
  // Counter
  // -----------------------------------------------
  // mcycle(12'hb00), cycle(12'hc00) ---------------
  always_ff @( negedge clk_in ) begin
    if (!rst_n)
        mcycle <= '0;
    else if (csr_we && (csr_waddr == 12'hb00))
        mcycle[31:0] <= wdata_tmp;
    else if (csr_we && (csr_waddr == 12'hb80))
        mcycle[63:32] <= wdata_tmp;
    else
        mcycle <= mcycle + 1'b1;
  end

  // minstret(12'hb02) -----------------------------
  always_ff @( negedge clk_in ) begin
    if (!rst_n)
        minstret <= '0;
    else if (csr_we && (csr_waddr == 12'hb02))
        minstret[31:0]  <= wdata_tmp;
    else if (csr_we && (csr_waddr == 12'hb82))
        minstret[63:32] <= wdata_tmp;
    else
        minstret <= retire ? minstret  + 1'b1 : minstret;
  end

endmodule
