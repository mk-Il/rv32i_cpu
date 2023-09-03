// Platform Level Interrupt Controller module

module PLIC (
  input  logic  [0:0] clk_in,
  input  logic  [0:0] rst_n,
  input  logic  [0:0] CS,
  input  logic [31:0] irq_in, // interrupt request from external devices
  input  logic  [0:0] dbus_we,
  input  logic  [3:0] dbus_addr4,
  input  logic [31:0] dbus_in,
  output logic [31:0] dbus_out,
  output logic  [0:0] irq_out // interrupt request to CPU core
  );

  assign irq_out = irq_in[0];

endmodule
