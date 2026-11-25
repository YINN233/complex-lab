`timescale 1ns / 1ps

`default_nettype none

module lab6_soc (
    input  wire        clk,
    input  wire        rst,

    output logic [15:0] leds,

    inout  wire  [31:0] base_ram_data,
    output logic [19:0] base_ram_addr,
    output logic [ 3:0] base_ram_be_n,
    output logic        base_ram_ce_n,
    output logic        base_ram_oe_n,
    output logic        base_ram_we_n,

    inout  wire  [31:0] ext_ram_data,
    output logic [19:0] ext_ram_addr,
    output logic [ 3:0] ext_ram_be_n,
    output logic        ext_ram_ce_n,
    output logic        ext_ram_oe_n,
    output logic        ext_ram_we_n,

    output logic        txd,
    input  wire        rxd
);

  logic [31:0] cpu_pc;
  logic cpu_illegal;

  logic if_req, if_ready, if_cyc, if_stb, if_ack;
  logic [31:0] if_addr, if_wb_addr, if_rdata, if_wb_rdata;
  logic mem_req, mem_ready, mem_we, mem_cyc, mem_stb, mem_wb_we, mem_ack;
  logic [31:0] mem_addr, mem_wdata, mem_rdata;
  logic [31:0] mem_wb_addr, mem_wb_wdata, mem_wb_rdata;
  logic [3:0] mem_sel, mem_wb_sel;

  logic        bus_cyc;
  logic        bus_stb;
  logic        bus_ack;
  logic [31:0] bus_adr;
  logic [31:0] bus_dat_o;
  logic [31:0] bus_dat_i;
  logic [ 3:0] bus_sel;
  logic        bus_we;

  logic wbs0_cyc;
  logic wbs0_stb;
  logic wbs0_ack;
  logic [31:0] wbs0_adr;
  logic [31:0] wbs0_dat_o;
  logic [31:0] wbs0_dat_i;
  logic [3:0] wbs0_sel;
  logic wbs0_we;

  logic wbs1_cyc;
  logic wbs1_stb;
  logic wbs1_ack;
  logic [31:0] wbs1_adr;
  logic [31:0] wbs1_dat_o;
  logic [31:0] wbs1_dat_i;
  logic [3:0] wbs1_sel;
  logic wbs1_we;

  logic wbs2_cyc;
  logic wbs2_stb;
  logic wbs2_ack;
  logic [31:0] wbs2_adr;
  logic [31:0] wbs2_dat_o;
  logic [31:0] wbs2_dat_i;
  logic [3:0] wbs2_sel;
  logic wbs2_we;

  assign leds = {cpu_illegal, cpu_pc[14:0]};

  lab6_core u_cpu (
      .clk_i(clk), .rst_i(rst),
      .imem_req_o(if_req), .imem_addr_o(if_addr),
      .imem_ack_i(if_ready), .imem_rdata_i(if_rdata),
      .dmem_req_o(mem_req), .dmem_addr_o(mem_addr), .dmem_we_o(mem_we),
      .dmem_sel_o(mem_sel), .dmem_wdata_o(mem_wdata),
      .dmem_ack_i(mem_ready), .dmem_rdata_i(mem_rdata),
      .pc_o(cpu_pc), .illegal_o(cpu_illegal),
      .retire_o(), .retire_pc_o(), .retire_inst_o()
  );

  wb_master u_if_master (
      .clk_i(clk), .rst_i(rst),
      .req_valid_i(if_req), .req_we_i(1'b0), .req_addr_i(if_addr),
      .req_wdata_i(32'b0), .req_sel_i(4'b1111),
      .resp_valid_o(if_ready), .resp_rdata_o(if_rdata),
      .wb_cyc_o(if_cyc), .wb_stb_o(if_stb), .wb_adr_o(if_wb_addr),
      .wb_dat_o(), .wb_sel_o(), .wb_we_o(),
      .wb_ack_i(if_ack), .wb_dat_i(if_wb_rdata)
  );

  wb_master u_mem_master (
      .clk_i(clk), .rst_i(rst),
      .req_valid_i(mem_req), .req_we_i(mem_we), .req_addr_i(mem_addr),
      .req_wdata_i(mem_wdata), .req_sel_i(mem_sel),
      .resp_valid_o(mem_ready), .resp_rdata_o(mem_rdata),
      .wb_cyc_o(mem_cyc), .wb_stb_o(mem_stb), .wb_adr_o(mem_wb_addr),
      .wb_dat_o(mem_wb_wdata), .wb_sel_o(mem_wb_sel), .wb_we_o(mem_wb_we),
      .wb_ack_i(mem_ack), .wb_dat_i(mem_wb_rdata)
  );

  lab6_wb_arbiter u_arbiter (
      .clk_i(clk), .rst_i(rst),
      .if_cyc_i(if_cyc), .if_stb_i(if_stb), .if_addr_i(if_wb_addr),
      .if_ack_o(if_ack), .if_rdata_o(if_wb_rdata),
      .mem_cyc_i(mem_cyc), .mem_stb_i(mem_stb), .mem_we_i(mem_wb_we),
      .mem_addr_i(mem_wb_addr), .mem_wdata_i(mem_wb_wdata), .mem_sel_i(mem_wb_sel),
      .mem_ack_o(mem_ack), .mem_rdata_o(mem_wb_rdata),
      .bus_cyc_o(bus_cyc), .bus_stb_o(bus_stb), .bus_we_o(bus_we),
      .bus_addr_o(bus_adr), .bus_wdata_o(bus_dat_o), .bus_sel_o(bus_sel),
      .bus_ack_i(bus_ack), .bus_rdata_i(bus_dat_i)
  );

  wb_mux_3 wb_mux (
      .clk(clk),
      .rst(rst),

      .wbm_adr_i(bus_adr),
      .wbm_dat_i(bus_dat_o),
      .wbm_dat_o(bus_dat_i),
      .wbm_we_i (bus_we),
      .wbm_sel_i(bus_sel),
      .wbm_stb_i(bus_stb),
      .wbm_ack_o(bus_ack),
      .wbm_err_o(),
      .wbm_rty_o(),
      .wbm_cyc_i(bus_cyc),

      .wbs0_addr    (32'h8000_0000),
      .wbs0_addr_msk(32'hFFC0_0000),
      .wbs0_adr_o(wbs0_adr),
      .wbs0_dat_i(wbs0_dat_i),
      .wbs0_dat_o(wbs0_dat_o),
      .wbs0_we_o (wbs0_we),
      .wbs0_sel_o(wbs0_sel),
      .wbs0_stb_o(wbs0_stb),
      .wbs0_ack_i(wbs0_ack),
      .wbs0_err_i('0),
      .wbs0_rty_i('0),
      .wbs0_cyc_o(wbs0_cyc),

      .wbs1_addr    (32'h8040_0000),
      .wbs1_addr_msk(32'hFFC0_0000),
      .wbs1_adr_o(wbs1_adr),
      .wbs1_dat_i(wbs1_dat_i),
      .wbs1_dat_o(wbs1_dat_o),
      .wbs1_we_o (wbs1_we),
      .wbs1_sel_o(wbs1_sel),
      .wbs1_stb_o(wbs1_stb),
      .wbs1_ack_i(wbs1_ack),
      .wbs1_err_i('0),
      .wbs1_rty_i('0),
      .wbs1_cyc_o(wbs1_cyc),

      .wbs2_addr    (32'h1000_0000),
      .wbs2_addr_msk(32'hFFFF_0000),
      .wbs2_adr_o(wbs2_adr),
      .wbs2_dat_i(wbs2_dat_i),
      .wbs2_dat_o(wbs2_dat_o),
      .wbs2_we_o (wbs2_we),
      .wbs2_sel_o(wbs2_sel),
      .wbs2_stb_o(wbs2_stb),
      .wbs2_ack_i(wbs2_ack),
      .wbs2_err_i('0),
      .wbs2_rty_i('0),
      .wbs2_cyc_o(wbs2_cyc)
  );

  sram_controller #(
      .SRAM_ADDR_WIDTH(20),
      .SRAM_DATA_WIDTH(32)
  ) u_base_sram (
      .clk_i(clk),
      .rst_i(rst),
      .wb_cyc_i(wbs0_cyc),
      .wb_stb_i(wbs0_stb),
      .wb_ack_o(wbs0_ack),
      .wb_adr_i(wbs0_adr),
      .wb_dat_i(wbs0_dat_o),
      .wb_dat_o(wbs0_dat_i),
      .wb_sel_i(wbs0_sel),
      .wb_we_i (wbs0_we),
      .sram_addr(base_ram_addr),
      .sram_data(base_ram_data),
      .sram_ce_n(base_ram_ce_n),
      .sram_oe_n(base_ram_oe_n),
      .sram_we_n(base_ram_we_n),
      .sram_be_n(base_ram_be_n)
  );

  sram_controller #(
      .SRAM_ADDR_WIDTH(20),
      .SRAM_DATA_WIDTH(32)
  ) u_ext_sram (
      .clk_i(clk),
      .rst_i(rst),
      .wb_cyc_i(wbs1_cyc),
      .wb_stb_i(wbs1_stb),
      .wb_ack_o(wbs1_ack),
      .wb_adr_i(wbs1_adr),
      .wb_dat_i(wbs1_dat_o),
      .wb_dat_o(wbs1_dat_i),
      .wb_sel_i(wbs1_sel),
      .wb_we_i (wbs1_we),
      .sram_addr(ext_ram_addr),
      .sram_data(ext_ram_data),
      .sram_ce_n(ext_ram_ce_n),
      .sram_oe_n(ext_ram_oe_n),
      .sram_we_n(ext_ram_we_n),
      .sram_be_n(ext_ram_be_n)
  );

  uart_controller #(
      .CLK_FREQ(10_000_000),
      .BAUD    (115200)
  ) u_uart (
      .clk_i(clk),
      .rst_i(rst),
      .wb_cyc_i(wbs2_cyc),
      .wb_stb_i(wbs2_stb),
      .wb_ack_o(wbs2_ack),
      .wb_adr_i(wbs2_adr),
      .wb_dat_i(wbs2_dat_o),
      .wb_dat_o(wbs2_dat_i),
      .wb_sel_i(wbs2_sel),
      .wb_we_i (wbs2_we),
      .uart_txd_o(txd),
      .uart_rxd_i(rxd)
  );

endmodule

`default_nettype wire
