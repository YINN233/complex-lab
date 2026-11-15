`timescale 1ns / 1ps

module lab5_tb;

  logic clk_50M = 0;
  logic clk_11M0592 = 0;
  logic push_btn = 0;
  logic reset_btn = 0;
  logic [3:0] touch_btn = 0;
  logic [31:0] dip_sw = 0;
  logic uart_dataready = 0;
  logic uart_tbre = 0;
  logic uart_tsre = 0;
  logic rxd = 1;
  logic sl811_intrq = 0;
  logic sl811_drq_n = 1;
  logic dm9k_int = 0;

  wire [15:0] leds;
  wire [7:0] dpy0;
  wire [7:0] dpy1;
  wire uart_rdn;
  wire uart_wrn;

  wire [31:0] base_ram_data;
  wire [19:0] base_ram_addr;
  wire [3:0] base_ram_be_n;
  wire base_ram_ce_n;
  wire base_ram_oe_n;
  wire base_ram_we_n;

  wire [31:0] ext_ram_data;
  wire [19:0] ext_ram_addr;
  wire [3:0] ext_ram_be_n;
  wire ext_ram_ce_n;
  wire ext_ram_oe_n;
  wire ext_ram_we_n;

  wire txd;

  wire [22:0] flash_a;
  wire [15:0] flash_d;
  wire flash_rp_n;
  wire flash_vpen;
  wire flash_ce_n;
  wire flash_oe_n;
  wire flash_we_n;
  wire flash_byte_n;

  wire sl811_a0;
  wire sl811_wr_n;
  wire sl811_rd_n;
  wire sl811_cs_n;
  wire sl811_rst_n;
  wire sl811_dack_n;

  wire dm9k_cmd;
  wire [15:0] dm9k_sd;
  wire dm9k_iow_n;
  wire dm9k_ior_n;
  wire dm9k_cs_n;
  wire dm9k_pwrst_n;

  wire [2:0] video_red;
  wire [2:0] video_green;
  wire [1:0] video_blue;
  wire video_hsync;
  wire video_vsync;
  wire video_clk;
  wire video_de;

  logic tb_clk = 0;
  logic tb_rst = 1;

  logic [7:0] tx_bytes [0:7];
  integer tx_count = 0;
  integer errors = 0;

  thinpad_top dut (
      .clk_50M(clk_50M),
      .clk_11M0592(clk_11M0592),
      .push_btn(push_btn),
      .reset_btn(reset_btn),
      .touch_btn(touch_btn),
      .dip_sw(dip_sw),
      .leds(leds),
      .dpy0(dpy0),
      .dpy1(dpy1),
      .uart_rdn(uart_rdn),
      .uart_wrn(uart_wrn),
      .uart_dataready(uart_dataready),
      .uart_tbre(uart_tbre),
      .uart_tsre(uart_tsre),
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
      .rxd(rxd),
      .flash_a(flash_a),
      .flash_d(flash_d),
      .flash_rp_n(flash_rp_n),
      .flash_vpen(flash_vpen),
      .flash_ce_n(flash_ce_n),
      .flash_oe_n(flash_oe_n),
      .flash_we_n(flash_we_n),
      .flash_byte_n(flash_byte_n),
      .sl811_a0(sl811_a0),
      .sl811_wr_n(sl811_wr_n),
      .sl811_rd_n(sl811_rd_n),
      .sl811_cs_n(sl811_cs_n),
      .sl811_rst_n(sl811_rst_n),
      .sl811_dack_n(sl811_dack_n),
      .sl811_intrq(sl811_intrq),
      .sl811_drq_n(sl811_drq_n),
      .dm9k_cmd(dm9k_cmd),
      .dm9k_sd(dm9k_sd),
      .dm9k_iow_n(dm9k_iow_n),
      .dm9k_ior_n(dm9k_ior_n),
      .dm9k_cs_n(dm9k_cs_n),
      .dm9k_pwrst_n(dm9k_pwrst_n),
      .dm9k_int(dm9k_int),
      .video_red(video_red),
      .video_green(video_green),
      .video_blue(video_blue),
      .video_hsync(video_hsync),
      .video_vsync(video_vsync),
      .video_clk(video_clk),
      .video_de(video_de)
  );

  sram_model_lab5 #(.MODE(0)) u_base (
      .data(base_ram_data),
      .addr(base_ram_addr),
      .ce_n(base_ram_ce_n),
      .oe_n(base_ram_oe_n),
      .we_n(base_ram_we_n),
      .be_n(base_ram_be_n)
  );

  sram_model_lab5 #(.MODE(0)) u_ext (
      .data(ext_ram_data),
      .addr(ext_ram_addr),
      .ce_n(ext_ram_ce_n),
      .oe_n(ext_ram_oe_n),
      .we_n(ext_ram_we_n),
      .be_n(ext_ram_be_n)
  );

  always #50 tb_clk = ~tb_clk;

  initial begin
    force dut.sys_clk = tb_clk;
    force dut.sys_rst = tb_rst;
    #300;
    tb_rst = 0;
  end

  always @(posedge tb_clk) begin
    if (dut.u_soc.u_uart.txd_start) begin
      tx_bytes[tx_count] = dut.u_soc.u_uart.txd_data;
      tx_count = tx_count + 1;
    end
  end

  initial begin
    #2_000_000;
    $display("TIMEOUT tx_count=%0d pc=%08h", tx_count, dut.u_soc.u_cpu.pc);
    $finish;
  end

  initial begin
    wait (tx_count == 5);
    repeat (50) @(posedge tb_clk);

    if (u_base.mem[32'h40] !== 32'h0000_13BA) begin
      $display("FAIL result=%08h", u_base.mem[32'h40]);
      errors = errors + 1;
    end

    if (tx_bytes[0] !== 8'h64 || tx_bytes[1] !== 8'h6F || tx_bytes[2] !== 8'h6E ||
        tx_bytes[3] !== 8'h65 || tx_bytes[4] !== 8'h21) begin
      $display("FAIL UART bytes: %02h %02h %02h %02h %02h",
               tx_bytes[0], tx_bytes[1], tx_bytes[2], tx_bytes[3], tx_bytes[4]);
      errors = errors + 1;
    end

    if (errors == 0) $display("LAB5 TOP TEST PASSED");
    else $display("LAB5 TOP TEST FAILED: %0d errors", errors);
    $finish;
  end

endmodule
