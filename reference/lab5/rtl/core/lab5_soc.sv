`timescale 1ns / 1ps

`default_nettype none

module lab5_soc (
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

  logic        cpu_wb_cyc;
  logic        cpu_wb_stb;
  logic        cpu_wb_ack;
  logic [31:0] cpu_wb_adr;
  logic [31:0] cpu_wb_dat_o;
  logic [31:0] cpu_wb_dat_i;
  logic [ 3:0] cpu_wb_sel;
  logic        cpu_wb_we;

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

  assign leds = cpu_pc[15:0];

  lab5_cpu u_cpu (
      .clk_i  (clk),
      .rst_i  (rst),
      .pc_o   (cpu_pc),
      .wb_cyc_o(cpu_wb_cyc),
      .wb_stb_o(cpu_wb_stb),
      .wb_adr_o(cpu_wb_adr),
      .wb_dat_o(cpu_wb_dat_o),
      .wb_sel_o(cpu_wb_sel),
      .wb_we_o (cpu_wb_we),
      .wb_ack_i(cpu_wb_ack),
      .wb_dat_i(cpu_wb_dat_i)
  );

  wb_mux_3 wb_mux (
      .clk(clk),
      .rst(rst),

      .wbm_adr_i(cpu_wb_adr),
      .wbm_dat_i(cpu_wb_dat_o),
      .wbm_dat_o(cpu_wb_dat_i),
      .wbm_we_i (cpu_wb_we),
      .wbm_sel_i(cpu_wb_sel),
      .wbm_stb_i(cpu_wb_stb),
      .wbm_ack_o(cpu_wb_ack),
      .wbm_err_o(),
      .wbm_rty_o(),
      .wbm_cyc_i(cpu_wb_cyc),

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
