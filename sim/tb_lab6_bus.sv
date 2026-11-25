`timescale 1ns / 1ps

module tb_lab6_bus;
  logic clk = 0, rst = 1;
  always #5 clk = ~clk;

  logic if_req = 0, mem_req = 0, slave_ack = 0;
  logic [31:0] slave_data = 0;
  wire if_ack, mem_ack, cyc, stb, we;
  wire [31:0] if_data, mem_data, addr, wdata;
  wire [3:0] sel;

  lab6_wb_arbiter dut (
      .clk_i(clk), .rst_i(rst),
      .if_cyc_i(if_req), .if_stb_i(if_req), .if_addr_i(32'h80000000),
      .if_ack_o(if_ack), .if_rdata_o(if_data),
      .mem_cyc_i(mem_req), .mem_stb_i(mem_req), .mem_we_i(1'b1),
      .mem_addr_i(32'h80400005), .mem_wdata_i(32'h0000_1200), .mem_sel_i(4'b0010),
      .mem_ack_o(mem_ack), .mem_rdata_o(mem_data),
      .bus_cyc_o(cyc), .bus_stb_o(stb), .bus_we_o(we), .bus_addr_o(addr),
      .bus_wdata_o(wdata), .bus_sel_o(sel), .bus_ack_i(slave_ack), .bus_rdata_i(slave_data)
  );

  task automatic check_if;
    if ({cyc, stb, we, addr, sel} !== {3'b110, 32'h80000000, 4'b1111})
      $fatal(1, "IF request not on bus");
  endtask

  task automatic check_mem;
    if ({cyc, stb, we, addr, wdata, sel} !==
        {3'b111, 32'h80400005, 32'h00001200, 4'b0010})
      $fatal(1, "MEM request not on bus");
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst = 0;
    if_req = 1;
    #1;
    check_if();
    @(negedge clk);
    mem_req = 1;
    repeat (3) begin
      #1;
      check_if();
      if (if_ack || mem_ack) $fatal(1, "unexpected ACK while IF waits");
      @(negedge clk);
    end
    slave_data = 32'hfedcba98;
    slave_ack = 1;
    #1;
    if (!if_ack || mem_ack || if_data !== slave_data) $fatal(1, "incorrect IF ACK");
    @(negedge clk);
    slave_ack = 0;
    if_req = 0;
    #1;
    check_mem();
    @(negedge clk);
    if_req = 1;
    slave_data = 32'h76543210;
    slave_ack = 1;
    #1;
    if (if_ack || !mem_ack || mem_data !== slave_data) $fatal(1, "incorrect MEM ACK");
    @(negedge clk);
    slave_ack = 0;
    #1;
    check_mem();  // Simultaneous new requests choose MEM.
    slave_ack = 1;
    @(negedge clk);
    mem_req = 0;
    slave_ack = 0;
    #1;
    check_if();
    $display("LAB6 BUS PASS");
    $finish;
  end
endmodule
