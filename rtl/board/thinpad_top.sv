`timescale 1ns / 1ps

`default_nettype none

module thinpad_top (
    input wire clk_50M,
    input wire clk_11M0592,

    input wire push_btn,
    input wire reset_btn,

    input  wire [ 3:0] touch_btn,
    input  wire [31:0] dip_sw,
    output wire [15:0] leds,
    output wire [ 7:0] dpy0,
    output wire [ 7:0] dpy1,

    output wire uart_rdn,
    output wire uart_wrn,
    input  wire uart_dataready,
    input  wire uart_tbre,
    input  wire uart_tsre,

    inout  wire [31:0] base_ram_data,
    output wire [19:0] base_ram_addr,
    output wire [ 3:0] base_ram_be_n,
    output wire        base_ram_ce_n,
    output wire        base_ram_oe_n,
    output wire        base_ram_we_n,

    inout  wire [31:0] ext_ram_data,
    output wire [19:0] ext_ram_addr,
    output wire [ 3:0] ext_ram_be_n,
    output wire        ext_ram_ce_n,
    output wire        ext_ram_oe_n,
    output wire        ext_ram_we_n,

    output wire txd,
    input  wire rxd,

    output wire [22:0] flash_a,
    inout  wire [15:0] flash_d,
    output wire        flash_rp_n,
    output wire        flash_vpen,
    output wire        flash_ce_n,
    output wire        flash_oe_n,
    output wire        flash_we_n,
    output wire        flash_byte_n,

    output wire sl811_a0,
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    output wire dm9k_cmd,
    inout  wire [15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    output wire [2:0] video_red,
    output wire [2:0] video_green,
    output wire [1:0] video_blue,
    output wire       video_hsync,
    output wire       video_vsync,
    output wire       video_clk,
    output wire       video_de
);

  logic locked;
  logic clk_10M;

  pll_example clock_gen (
      .clk_in1 (clk_50M),
      .clk_out1(clk_10M),
      .clk_out2(),
      .reset   (reset_btn),
      .locked  (locked)
  );

  logic sys_clk;
  logic sys_rst;

  logic reset_of_clk10M;

  always_ff @(posedge clk_10M or negedge locked) begin
    if (~locked) reset_of_clk10M <= 1'b1;
    else reset_of_clk10M <= 1'b0;
  end

  // DIP0 selects single-step mode. BTN5 advances the CPU and bus one cycle.
  (* ASYNC_REG = "TRUE" *) logic [1:0] debug_sync, button_sync;
  logic [15:0] debounce_count;
  logic stable_button, step_pulse;
  always_ff @(posedge clk_10M) begin
    if (reset_of_clk10M) begin
      debug_sync <= '0;
      button_sync <= '0;
      debounce_count <= '0;
      stable_button <= 0;
      step_pulse <= 0;
    end else begin
      debug_sync <= {debug_sync[0], dip_sw[0]};
      button_sync <= {button_sync[0], push_btn};
      step_pulse <= 0;
      if (button_sync[1] == stable_button) begin
        debounce_count <= '0;
      end else if (debounce_count == 16'd49999) begin
        stable_button <= button_sync[1];
        debounce_count <= '0;
        step_pulse <= button_sync[1];
      end else begin
        debounce_count <= debounce_count + 1'b1;
      end
    end
  end

  BUFGCE #(.SIM_DEVICE("7SERIES")) run_or_step (
      .I(clk_10M), .CE(reset_of_clk10M || !debug_sync[1] || step_pulse), .O(sys_clk)
  );
  assign sys_rst = reset_of_clk10M;

  assign uart_rdn = 1'b1;
  assign uart_wrn = 1'b1;

  assign dpy0 = 8'hff;
  assign dpy1 = 8'hff;

  assign flash_a     = 23'b0;
  assign flash_d     = 16'bz;
  assign flash_rp_n  = 1'b1;
  assign flash_vpen  = 1'b1;
  assign flash_ce_n  = 1'b1;
  assign flash_oe_n  = 1'b1;
  assign flash_we_n  = 1'b1;
  assign flash_byte_n = 1'b1;

  assign sl811_a0    = 1'b0;
  assign sl811_wr_n  = 1'b1;
  assign sl811_rd_n  = 1'b1;
  assign sl811_cs_n  = 1'b1;
  assign sl811_rst_n = 1'b1;
  assign sl811_dack_n = 1'b1;

  assign dm9k_cmd    = 1'b0;
  assign dm9k_sd     = 16'bz;
  assign dm9k_iow_n  = 1'b1;
  assign dm9k_ior_n  = 1'b1;
  assign dm9k_cs_n   = 1'b1;
  assign dm9k_pwrst_n = 1'b1;

  assign video_red   = 3'b0;
  assign video_green = 3'b0;
  assign video_blue  = 2'b0;
  assign video_hsync = 1'b0;
  assign video_vsync = 1'b0;
  assign video_clk   = 1'b0;
  assign video_de    = 1'b0;

  lab6_soc u_soc (
      .clk(sys_clk),
      .rst(sys_rst),
      .leds(leds),
      .base_ram_data(base_ram_data),
      .base_ram_addr(base_ram_addr),
      .base_ram_be_n(base_ram_be_n),
      .base_ram_ce_n(base_ram_ce_n),
      .base_ram_oe_n(base_ram_oe_n),
      .base_ram_we_n(base_ram_we_n),
      .ext_ram_data(ext_ram_data),
      .ext_ram_addr(ext_ram_addr),
      .ext_ram_be_n(ext_ram_be_n),
      .ext_ram_ce_n(ext_ram_ce_n),
      .ext_ram_oe_n(ext_ram_oe_n),
      .ext_ram_we_n(ext_ram_we_n),
      .txd(txd),
      .rxd(rxd)
  );

endmodule

`default_nettype wire
