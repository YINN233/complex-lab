module wb_uart_model (
    input  logic        clk,
    input  logic        rst,
    input  logic        wb_cyc,
    input  logic        wb_stb,
    input  logic        wb_we,
    input  logic [31:0] wb_adr,
    input  logic [31:0] wb_dat_i,
    input  logic [ 3:0] wb_sel,
    output logic        wb_ack,
    output logic [31:0] wb_dat_o,
    output logic        tx_valid,
    output logic [ 7:0] tx_data
);

  always_ff @(posedge clk) begin
    if (rst) begin
      wb_ack   <= 1'b0;
      tx_valid <= 1'b0;
      tx_data  <= 8'b0;
    end else begin
      if (wb_ack) wb_ack <= 1'b0;
      else wb_ack <= wb_stb;

      tx_valid <= 1'b0;
      if (wb_stb && wb_we && (wb_adr[7:0] == 8'h00) && wb_sel[0]) begin
        tx_data  <= wb_dat_i[7:0];
        tx_valid <= 1'b1;
      end
    end
  end

  always_comb begin
    if (wb_adr[7:0] == 8'h05) wb_dat_o = 32'h0000_0020;
    else wb_dat_o = 32'h0000_0000;
  end

endmodule
