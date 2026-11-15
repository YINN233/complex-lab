`timescale 1ns / 1ps

module tb_lab5_cpu;

  logic clk = 0;
  logic rst = 1;

  logic [15:0] leds;

  wire [31:0] base_ram_data;
  wire [19:0] base_ram_addr;
  wire [ 3:0] base_ram_be_n;
  wire        base_ram_ce_n;
  wire        base_ram_oe_n;
  wire        base_ram_we_n;

  wire [31:0] ext_ram_data;
  wire [19:0] ext_ram_addr;
  wire [ 3:0] ext_ram_be_n;
  wire        ext_ram_ce_n;
  wire        ext_ram_oe_n;
  wire        ext_ram_we_n;

  wire txd;
  logic rxd = 1;

  logic [7:0] tx_bytes [0:7];
  integer     tx_count = 0;
  integer     errors = 0;
  integer     i;
  logic       prev_wb_stb = 0;

  lab5_soc dut (
      .clk(clk),
      .rst(rst),
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

  always #50 clk = ~clk;

  always @(posedge clk) begin
    if (dut.u_uart.txd_start) begin
      tx_bytes[tx_count] = dut.u_uart.txd_data;
      $display("UART[%0d] = %02h (%c)", tx_count, dut.u_uart.txd_data, dut.u_uart.txd_data);
      tx_count = tx_count + 1;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      prev_wb_stb <= 1'b0;
    end else begin
      prev_wb_stb <= dut.u_cpu.wb_stb_o;
      if (dut.u_cpu.wb_stb_o && !prev_wb_stb && dut.u_cpu.wb_we_o) begin
        if (dut.u_cpu.wb_adr_o == 32'h8000_0100)
          $display("MEM WRITE: pc=%08h inst=%08h addr=%08h data=%08h",
                   dut.u_cpu.pc_now, dut.u_cpu.inst, dut.u_cpu.wb_adr_o, dut.u_cpu.wb_dat_o);
        if (dut.u_cpu.wb_adr_o == 32'h1000_0000)
          $display("UART WRITE: pc=%08h inst=%08h data=%08h",
                   dut.u_cpu.pc_now, dut.u_cpu.inst, dut.u_cpu.wb_dat_o);
      end
    end
  end

  initial begin
    #300;
    rst = 0;
  end

  initial begin
    #2_000_000;
    $display("TIMEOUT tx_count=%0d pc=%08h", tx_count, dut.u_cpu.pc);
    $finish;
  end

  initial begin
    wait (tx_count == 5);
    repeat (50) @(posedge clk);

    if (u_base.mem[32'h40] !== 32'h0000_13BA) begin
      $display("FAIL result mem[0x100]=%08h", u_base.mem[32'h40]);
      errors = errors + 1;
    end

    if (tx_count != 5) begin
      $display("FAIL tx_count=%0d", tx_count);
      errors = errors + 1;
    end

    if (tx_bytes[0] !== 8'h64 || tx_bytes[1] !== 8'h6F || tx_bytes[2] !== 8'h6E ||
        tx_bytes[3] !== 8'h65 || tx_bytes[4] !== 8'h21) begin
      $display("FAIL UART bytes: %02h %02h %02h %02h %02h",
               tx_bytes[0], tx_bytes[1], tx_bytes[2], tx_bytes[3], tx_bytes[4]);
      errors = errors + 1;
    end

    if (dut.u_cpu.pc !== 32'h8000_008C) begin
      $display("FAIL end pc=%08h", dut.u_cpu.pc);
      errors = errors + 1;
    end

    if (errors == 0) $display("LAB5 CPU TEST PASSED");
    else $display("LAB5 CPU TEST FAILED: %0d errors", errors);
    $finish;
  end

endmodule
