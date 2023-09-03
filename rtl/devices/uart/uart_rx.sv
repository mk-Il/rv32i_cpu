// UART RX module


module UART_RX #(
  parameter OSR = 16 // Over Sampling Rate
  )(
  input  logic [0:0] s_tick,
  input  logic [0:0] rx,
  input  logic [0:0] re, // read enable
  output logic [2:0] rx_state,
  output logic [0:0] rx_data_ready,
  output logic [0:0] rx_busy,
  output logic [7:0] rxdata
  );

  // Parameters & registers
  localparam RX_STATE_IDLE  = 3'b000;
  localparam RX_STATE_START = 3'b001;
  localparam RX_STATE_DATA  = 3'b011;
  localparam RX_STATE_STOP  = 3'b010;
  localparam RX_STATE_DONE  = 3'b110;
  logic [2:0] state = RX_STATE_IDLE;
  
  logic [3:0] tick_cnt = 4'b0;
  logic [3:0] bit_cnt  = 4'b0;
  logic [7:0] rxbuf8   = 8'b0;

  // ---------------------------------
  // State machine
  // ---------------------------------
  always_ff @( posedge s_tick ) begin
    case (state)

      RX_STATE_IDLE: begin
          state <= rx ? RX_STATE_IDLE : RX_STATE_START;
          {bit_cnt, tick_cnt} <= '0;
          if (!rx) tick_cnt <= 4'b1;
      end

      RX_STATE_START: begin
          tick_cnt <= (tick_cnt == OSR-1) ? 4'b0 : tick_cnt + 1'b1;
          state    <= (tick_cnt == OSR-1) ? RX_STATE_DATA : RX_STATE_START;
      end

      RX_STATE_DATA: begin
          state    <= (bit_cnt[3] && tick_cnt == OSR-1) ? RX_STATE_STOP : RX_STATE_DATA;
          tick_cnt <= (tick_cnt == OSR-1) ? 4'b0 : tick_cnt + 1'b1;

          if (tick_cnt == (OSR/2)-1) begin
            rxbuf8[bit_cnt] <= rx; // rxbuf8 <= {rxbuf8[6:0], rx};
            bit_cnt <= bit_cnt + 1'b1;
          end else if (bit_cnt[3] && tick_cnt == OSR-1) begin // bit_cnt == 4'b1000 
            bit_cnt <= 4'b0;
          end
      end // RX_STATE_DATA

      RX_STATE_STOP: begin
          state    <= rx ? RX_STATE_DONE : RX_STATE_STOP;
          rxdata   <= rxbuf8;
          tick_cnt <= (tick_cnt == OSR-1) ? 4'b0 : tick_cnt + 1'b1;
      end

      RX_STATE_DONE: state <= re ? RX_STATE_IDLE : RX_STATE_DONE;

    endcase
  end // always_ff @( posedge s_tick )

  assign rx_state      = state;
  assign rx_busy       = !(state == RX_STATE_IDLE);
  assign rx_data_ready = state == RX_STATE_DONE;
  
endmodule
