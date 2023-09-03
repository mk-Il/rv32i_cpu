// Register file module
//
// RISC-V RV32 registers
//
// |     | ABI name | Description                          |  Saver |
// |-----|----------|--------------------------------------|--------|
// |  x0 |   zero   | hard-wired zero                      |   -    |
// |  x1 |    ra    | return address                       | Caller |
// |  x2 |    sp    | stack pointer                        | Callee |
// |  x3 |    gp    | global pointer                       |    -   |
// |  x4 |    tp    | thread pointer                       |    -   |
// |  x5 |    t0    | temporary register 0                 | Caller |
// |  x6 |    t1    | temporary register 1                 | Caller |
// |  x7 |    t2    | temporary register 2                 | Caller |
// |  x8 |   s0/fp  | saved register 0 / frame pointer     | Callee |
// |  x9 |    s1    | saved register 1                     | Callee |
// | x10 |    a0    | function argument 0 / return value 0 | Caller |
// | x11 |    a1    | function argument 1 / return value 1 | Caller |
// | x12 |    a2    | function argument 2                  | Caller |
// | x13 |    a3    | function argument 3                  | Caller |
// | x14 |    a4    | function argument 4                  | Caller |
// | x15 |    a5    | function argument 5                  | Caller |
// | x16 |    a6    | function argument 6                  | Caller |
// | x17 |    a7    | function argument 7                  | Caller |
// | x18 |    s2    | saved register 2                     | Callee |
// | x19 |    s3    | saved register 3                     | Callee |
// | x20 |    s4    | saved register 4                     | Callee |
// | x21 |    s5    | saved register 5                     | Callee |
// | x22 |    s6    | saved register 6                     | Callee |
// | x23 |    s7    | saved register 7                     | Callee |
// | x24 |    s8    | saved register 8                     | Callee |
// | x25 |    s9    | saved register 9                     | Callee |
// | x26 |   s10    | saved register 10                    | Callee |
// | x27 |   s11    | saved register 11                    | Callee |
// | x28 |    t3    | temporary register 3                 | Caller |
// | x29 |    t4    | temporary register 4                 | Caller |
// | x30 |    t5    | temporary register 5                 | Caller |
// | x31 |    t6    | temporary register 6                 | Caller |


module Regfile (
  input  logic  [0:0] clk_in, //rst_n,
  input  logic  [0:0] we, // write enable
  input  logic  [4:0] waddr,
  input  logic [31:0] wdata,
  input  logic  [4:0] rs1addr, rs2addr,
  output logic [31:0] rs1, rs2
  );

  logic [31:0] x[31:0];
  
  // Read
  assign rs1 = (rs1addr == 0) ? 32'd0 : x[rs1addr];
  assign rs2 = (rs2addr == 0) ? 32'd0 : x[rs2addr];

  // Write
  always_ff @( negedge clk_in ) begin
    if (we) x[waddr] <= wdata;
  end

endmodule
