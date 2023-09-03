// UART TX module


module UART_TX (
  input  logic [0:0] baud_tick,
  input  logic [0:0] we,
  input  logic [7:0] txdata,
  output logic [1:0] tx_state,
  output logic [0:0] tx,
  );

  // Parameters & registers
  localparam TX_STATE_IDLE  = 2'b00;
  localparam TX_STATE_START = 2'b01;
  localparam TX_STATE_DATA  = 2'b11;
  localparam TX_STATE_STOP  = 2'b10;
  logic [1:0] state = TX_STATE_IDLE;
  
  logic [7:0] txbuf8  = '0;
  logic [3:0] bit_cnt = '0;
  
  // ---------------------------------
  // State machine
  // ---------------------------------
  always_ff @( posedge baud_tick ) begin
    case (state)
      TX_STATE_IDLE: begin
        tx      <= 1'b1;
        bit_cnt <= '0;
        if (we) begin
          state  <= TX_STATE_START;
          txbuf8 <= txdata;
        end
      end
      TX_STATE_START: begin
        tx    <= 1'b0; // start bit
        state <= TX_STATE_DATA;
      end
      TX_STATE_DATA: begin
        bit_cnt <= bit_cnt + 1'b1;
        tx      <= txbuf8[0];
        txbuf8  <= {1'b1, txbuf8[7:1]};
        if (bit_cnt[3]) begin // bit_cnt == 4'b1000
          state   <= TX_STATE_STOP;
          bit_cnt <= 4'b0;
        end
      end
      TX_STATE_STOP: begin
        txbuf8 <= '0;
        state  <= TX_STATE_IDLE;
      end
    endcase
  end // always_ff @( posedge baud_tick )

  assign tx_state  = state;
  
endmodule
