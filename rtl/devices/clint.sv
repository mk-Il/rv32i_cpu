// Core local interrupt module

module CLINT #(
  parameter NDIV = 720
  )(
  input  logic  [0:0] clk_in,
  input  logic  [0:0] rst_n,
  input  logic  [0:0] CS,      // Chip Select
  input  logic  [0:0] dbus_we,
  input  logic  [4:0] dbus_addr5,
  input  logic [31:0] dbus_in,
  output logic [31:0] dbus_out,
  output logic  [0:0] timer_irq
  );

  localparam NDIV_LEN = $clog2(NDIV) + 1;
  logic [NDIV_LEN-1:0] clk_cnt  = '0;

  // Write & counter
  logic [31:0] mtime, mtimecmp, interval;
  always_ff @( posedge clk_in ) begin
    if (!rst_n) begin
        {mtime, mtimecmp, clk_cnt} <= '0;
    end else if (CS && dbus_we) begin
      case (dbus_addr5)
        5'h0:  mtime    <= dbus_in;
        5'h8:  mtimecmp <= dbus_in;
        5'h10: interval <= dbus_in;
        //4'h4: mtime[63:32]    <= dbus_in;
        //4'hc: mtimecmp[63:32] <= dbus_in;
      endcase
    end else begin
      if (clk_cnt == NDIV) begin
          clk_cnt <= '0;
          mtime   <= mtime + 1'b1;
      end else begin
          clk_cnt <= clk_cnt + 1'b1;
      end
    end
  end // always_ff

  // Read
  always_comb begin
    case (dbus_addr5)
      5'h0:    dbus_out = mtime;
      5'h8:    dbus_out = mtimecmp;
      5'h10:   dbus_out = interval;
      default: dbus_out = '0;
      //4'h4: dbus_out = mtime[63:32];
      //4'hc: dbus_out = mtimecmp[63:32];
    endcase
  end

  assign timer_irq = (mtimecmp != '0) && (mtime >= mtimecmp);

endmodule
