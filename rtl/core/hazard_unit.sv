// Hazard unit


module HazardUnit (
  input  logic [4:0] rs1addr_d, // rs1addr from decode stage
  input  logic [4:0] rs2addr_d, // rs2addr from decode stage
  input  logic [4:0] rd_e,      // rd from execution stage
  input  logic [0:0] is_load_e, // load instruction?
  input  logic [0:0] fence_d,
  input  logic [0:0] fence_m,
  output logic [0:0] stall
  );

  // stall when trying to use the value loaded
  // from memory right after load instruction
  wire [0:0] load_stall = is_load_e && (rd_e == rs1addr_d || rd_e == rs2addr_d) && rd_e != '0;

  // Fence stall (wait until all instructions before fence are executed)
  wire [0:0] fence_stall = {fence_d,fence_m} == 2'b10;

  assign stall = load_stall || fence_stall;

endmodule
