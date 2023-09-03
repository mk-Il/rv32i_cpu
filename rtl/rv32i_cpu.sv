// RISC-V CPU top module

module RV32I_CPU #(
  parameter ROM_SIZE   = 4*1024, // [byte]
  parameter RAM_SIZE   = 4*1024, // [byte]
  parameter UART_NDIV1 = 39,     // 469(9600), 39(115200)
  parameter UART_NDIV2 = 625,    // 7500(9600), 625(115200)
  parameter UART_OSR   = 16,     // Over Sampling Rate
  parameter CLINT_NDIV = 720
  )(
  input  logic [0:0] clk_in, rst,
  // 7seg interface
  output logic [3:0] an,
  output logic [6:0] seg,
  // UART interface
  input  logic [0:0] rx,
  output logic [0:0] tx
  );

  // Wires
  logic  [3:0] dbus_we; // byte write enable
  logic [31:0] imem_addr;
  logic [31:0] doutA_rom;
  logic [31:0] doutB_ram;
  logic [31:0] dbus_addr;
  logic [31:0] dbus_wdata;
  logic [31:0] dbus_rdata;
  logic  [0:0] rst_sig;
  logic [31:0] dout_uart;
  logic [31:0] dout_ram;
  logic [31:0] doutB_rom;
  logic  [0:0] clk_pll_out;
  logic  [0:0] clk_pll_out2;
  logic  [0:0] locked;
  logic [31:0] dout_clint;
  logic  [0:0] timer_irq;
  logic [31:0] dout_plic;
  logic  [0:0] irq_out;

  // -----------------------------------------------
  // Address decoder for Memory Mapped I/O
  // -----------------------------------------------
  localparam ROM_BASE   = 32'h0000_0000;
  localparam CLINT_BASE = 32'h0200_0000;
  localparam PLIC_BASE  = 32'h0c00_0000;
  localparam UART_BASE  = 32'h1000_0000;
  localparam SEG7_BASE  = 32'h2000_0000;
  localparam RAM_BASE   = 32'h8000_0000;

  // Data bus
  struct packed {
    logic [0:0] rom, uart, plic, clint, seg7, ram;
  } chipselect_dbus; // one-hot

  assign chipselect_dbus.rom   = dbus_addr inside {[ROM_BASE:CLINT_BASE-1]};
  assign chipselect_dbus.clint = dbus_addr inside {[CLINT_BASE:PLIC_BASE-1]};
  assign chipselect_dbus.plic  = dbus_addr inside {[PLIC_BASE:UART_BASE-1]};
  assign chipselect_dbus.uart  = dbus_addr[31:4] == UART_BASE[31:4];
  assign chipselect_dbus.seg7  = dbus_addr[31:2] == SEG7_BASE[31:2];
  assign chipselect_dbus.ram   = ~|chipselect_dbus[5:1];

  always_comb begin
    if      (chipselect_dbus.rom)   dbus_rdata = doutB_rom;
    else if (chipselect_dbus.clint) dbus_rdata = dout_clint;
    else if (chipselect_dbus.plic)  dbus_rdata = dout_plic;
    else if (chipselect_dbus.uart)  dbus_rdata = dout_uart;
    else if (chipselect_dbus.ram)   dbus_rdata = dout_ram;
    else                            dbus_rdata = '0;
  end
  
  logic [31:0] dbus_addrA_decoded;
  assign dbus_addrA_decoded = dbus_addr - ({32{chipselect_dbus.ram}} & RAM_BASE);
  
  // Instruction
  wire  [0:0] chipselect_ibus    = imem_addr inside {[RAM_BASE:32'hffff_ffff]};
  wire [31:0] ibus_addrB_decoded = imem_addr - ({32{chipselect_ibus}} & RAM_BASE);
  wire [31:0] imem_rdata         = chipselect_ibus ? doutB_ram : doutA_rom;

  // -----------------------------------------------
  // Instantiate cpu core, memory & peripherals
  // -----------------------------------------------
  clk_wiz_0 clk_wizard (
    // in
    .resetn        (1'b1),
    .clk_100mhz    (clk_in),
    // out
    .clk_out_72mhz (clk_pll_out),
    .locked        (locked)
  );
  
  POR por (
    .clk_in  (clk_pll_out),
    .rst_n   (rst),
    .rst_out (rst_sig)
  );

  RV32I_core rv32i (
    .clk_in     (clk_pll_out),
    .rst_n      (rst_sig && locked),
    .ext_irq    (irq_out),
    .timer_irq  (timer_irq),
    .sw_irq     (1'b0),
    .imem_rdata (imem_rdata),
    .dbus_rdata (dbus_rdata),
    .dbus_we    (dbus_we),
    .imem_addr  (imem_addr),
    .dbus_addr  (dbus_addr),
    .dbus_wdata (dbus_wdata)
  );
  
  InstROM #(
    .ROM_SIZE (ROM_SIZE)
  ) rom (
    //.clk_in   (clk_pll_out),
    .addrA    (ibus_addrB_decoded),
    .doutA    (doutA_rom),
    .addrB    (dbus_addrA_decoded),
    .doutB    (doutB_rom)
  );

  DataRAM #(
    .RAM_SIZE (RAM_SIZE)
  ) dram (
    .clk_in   (clk_pll_out),
    .CS       (chipselect_dbus.ram),
    .we4      (dbus_we),
    .addrA    (dbus_addrA_decoded),
    .dinA     (dbus_wdata),
    .doutA    (dout_ram),
    .addrB    (ibus_addrB_decoded),
    .doutB    (doutB_ram)
  );

  // peripherals
  CLINT #(
    .NDIV       (CLINT_NDIV)
  ) clint (
    .clk_in     (clk_pll_out),
    .rst_n      (rst_sig && locked),
    .CS         (chipselect_dbus.clint),
    .dbus_we    (dbus_we[0]),
    .dbus_addr5 (dbus_addrA_decoded[4:0]),
    .dbus_in    (dbus_wdata),
    .dbus_out   (dout_clint),
    .timer_irq  (timer_irq)
  );
  
  PLIC plic (
    .clk_in     (clk_pll_out),
    .rst_n      (rst_sig && locked),
    .CS         (chipselect_dbus.plic),
    .dbus_we    (dbus_we[0]),
    .dbus_addr4 (dbus_addrA_decoded[3:0]),
    .dbus_in    (dbus_wdata),
    .dbus_out   (dout_plic),
    .irq_in     (32'b0),
    .irq_out    (irq_out)
  );

  UART #(
    .NDIV1     (UART_NDIV1),
    .NDIV2     (UART_NDIV2),
    .OSR       (UART_OSR)
  ) uart (
    .clk_in    (clk_pll_out),
    //.rst_n     (rst_sig && locked),
    // Data bus
    .CS        (chipselect_dbus.uart),
    .dbus_we   (dbus_we[0]),
    .dbus_addr (dbus_addrA_decoded[3:0]),
    .dbus_in   (dbus_wdata),
    .dbus_out  (dout_uart),
    // UART signals
    .rx        (rx),
    .tx        (tx)
  );
  
  Decoder_7seg decoder7seg (
    .clk_in    (clk_pll_out),
    .rst_n     (rst_sig && locked),
    // Data bus
    .CS        (chipselect_dbus.seg7),
    //.dbus_addr (dbus_addr),
    .dbus_in   (dbus_wdata),
    //.dbus_out  (dmem_rdata),
    // 7seg outputs
    .an        (an),
    .seg       (seg)
  );

endmodule
