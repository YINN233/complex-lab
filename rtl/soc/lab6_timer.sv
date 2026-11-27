`timescale 1ns / 1ps

module lab6_timer (
    input  logic        clk_i, rst_i,
    input  logic        wb_cyc_i, wb_stb_i, wb_we_i,
    input  logic [31:0] wb_addr_i, wb_wdata_i,
    input  logic [3:0]  wb_sel_i,
    output logic        wb_ack_o,
    output logic [31:0] wb_rdata_o,
    output logic        timer_irq_o
);
  localparam logic [31:0] MTIME_ADDR = 32'h0200_bff8;
  localparam logic [31:0] MTIMECMP_ADDR = 32'h0200_4000;

  logic [63:0] mtime, mtimecmp;
  logic select_time, select_compare, request, write_request;

  assign select_time = wb_addr_i[31:3] == MTIME_ADDR[31:3];
  assign select_compare = wb_addr_i[31:3] == MTIMECMP_ADDR[31:3];
  assign request = wb_cyc_i && wb_stb_i && !wb_ack_o &&
                   (select_time || select_compare);
  assign write_request = request && wb_we_i && (|wb_sel_i);
  assign timer_irq_o = mtime >= mtimecmp;

  function automatic logic [31:0] write_bytes(
      input logic [31:0] old_word, new_word,
      input logic [3:0] select_bytes
  );
    for (int lane = 0; lane < 4; ++lane) begin
      write_bytes[lane * 8 +: 8] = select_bytes[lane] ?
          new_word[lane * 8 +: 8] : old_word[lane * 8 +: 8];
    end
  endfunction

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      mtime <= '0;
      mtimecmp <= '1;
      wb_ack_o <= 0;
      wb_rdata_o <= '0;
    end else begin
      wb_ack_o <= request;
      if (request && !wb_we_i) begin
        if (select_time)
          wb_rdata_o <= wb_addr_i[2] ? mtime[63:32] : mtime[31:0];
        else
          wb_rdata_o <= wb_addr_i[2] ? mtimecmp[63:32] : mtimecmp[31:0];
      end

      // ThinPAD drives this clock at 10 MHz, the monitor's CLINT timebase.
      if (write_request && select_time) begin
        if (wb_addr_i[2])
          mtime[63:32] <= write_bytes(mtime[63:32], wb_wdata_i, wb_sel_i);
        else
          mtime[31:0] <= write_bytes(mtime[31:0], wb_wdata_i, wb_sel_i);
      end else begin
        mtime <= mtime + 64'd1;
      end

      if (write_request && select_compare) begin
        if (wb_addr_i[2])
          mtimecmp[63:32] <= write_bytes(mtimecmp[63:32], wb_wdata_i, wb_sel_i);
        else
          mtimecmp[31:0] <= write_bytes(mtimecmp[31:0], wb_wdata_i, wb_sel_i);
      end
    end
  end
endmodule
