// UART top module

//`define UART_BASE 32'h1000_0000
`define UART_RDR 4'b0100 // Received Data Register (offset from base address)
`define UART_TDR 4'b1000 // Transmit Data Register (offset from base address)
`define UART_SSR 4'b1100 // Serial Status Register (offset from base address)


module UART #(
  parameter NDIV1 = 39,
  parameter NDIV2 = 625,
  parameter OSR   = 16    // Over Sampling Rate
  )(
  input  logic  [0:0] clk_in,  // system clock
  // Data bus
  input  logic  [0:0] CS,      // Chip Select
  input  logic  [0:0] dbus_we,
  input  logic  [3:0] dbus_addr,
  input  logic [31:0] dbus_in,
  output logic [31:0] dbus_out,
  // UART signals
  input  logic  [0:0] rx,
  output logic  [0:0] tx
  );

  wire [0:0] baud_tick_o, baud_tick2_o;

  // UART registers for MMIO
  logic [7:0] uart_ssr; // 0x0 (Read only)
  logic [7:0] uart_rdr; // 0x1 (Read only)
  logic [7:0] uart_tdr = '0; // 0x2 (R/W)

  logic [0:0] rx_busy, rx_data_ready, tx_enable; // Status bits
  assign uart_ssr = {5'b0, rx_busy, rx_data_ready, tx_enable};

  logic [0:0] uart_re; // read enable
  logic [0:0] uart_we; // write enable
  assign uart_re = CS && (dbus_addr == `UART_RDR);
  assign uart_we = CS && (dbus_addr == `UART_TDR) && dbus_we;

  // Read
  always_comb begin
    if (CS) begin
      case (dbus_addr)
        `UART_RDR: dbus_out = 32'(unsigned'(uart_rdr));
        `UART_TDR: dbus_out = 32'(unsigned'(uart_tdr));
        `UART_SSR: dbus_out = 32'(unsigned'(uart_ssr));
        default:   dbus_out = '0;
      endcase
    end else dbus_out = '0;
  end // always_comb

  // Write
  localparam TX_STATE_IDLE  = 2'b00;
  localparam TX_STATE_START = 2'b01;
  logic [1:0] tx_state;
  logic [0:0] tx_start = '0;
  always_ff @( posedge clk_in ) begin
    uart_tdr <= uart_we ? dbus_in[7:0] : uart_tdr;

    if      (tx_state == TX_STATE_IDLE && uart_we) tx_start <= 1'b1;
    else if (tx_state == TX_STATE_START)           tx_start <= 1'b0;
  end
  assign tx_enable = (tx_state == TX_STATE_IDLE) && !tx_start;

  localparam RX_STATE_IDLE  = 3'b000;
  localparam RX_STATE_DONE  = 3'b110;
  logic [2:0] rx_state;
  logic [0:0] rx_read = '0;
  always_ff @( posedge clk_in ) begin
    if      (rx_state == RX_STATE_DONE && uart_re) rx_read <= 1'b1;
    else if (rx_state == RX_STATE_IDLE)            rx_read <= 1'b0;
  end

  BaudGen #(
    .NDIV1     (NDIV1),
    .NDIV2     (NDIV2)
  ) baud_gen (
    .clk_in    (clk_in),
    .tick      (baud_tick_o),
    .baud_tick (baud_tick2_o)
  );
  
  UART_RX #(
    .OSR           (OSR)
  ) uart_rx (
    .s_tick        (baud_tick_o),
    .rx            (rx),
    .re            (rx_read),
    .rx_state      (rx_state),
    .rx_data_ready (rx_data_ready),
    .rx_busy       (rx_busy), //(uart_ssr[1]),
    .rxdata        (uart_rdr)
  );

  UART_TX uart_tx (
    .baud_tick (baud_tick2_o),
    .we        (tx_start),
    .txdata    (uart_tdr),
    .tx_state  (tx_state),
    .tx        (tx)
  );

endmodule
