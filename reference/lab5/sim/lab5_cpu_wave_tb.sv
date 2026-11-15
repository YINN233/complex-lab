`timescale 1ns / 1ps

module lab5_cpu_wave_tb;

  logic clk = 0;
  logic rst = 1;

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

  logic wbs2_cyc;
  logic wbs2_stb;
  logic wbs2_ack;
  logic [31:0] wbs2_adr;
  logic [31:0] wbs2_dat_o;
  logic [31:0] wbs2_dat_i;
  logic [3:0] wbs2_sel;
  logic wbs2_we;

  wire [31:0] sram_data;
  wire [19:0] sram_addr;
  wire [3:0] sram_be_n;
  wire sram_ce_n;
  wire sram_oe_n;
  wire sram_we_n;

  logic uart_valid;
  logic [7:0] uart_data;
  logic [7:0] captured_uart;
  logic       prev_wb_stb = 0;
  integer errors = 0;

`ifdef VCD_DUMP
  initial begin
    $dumpfile("lab5_cpu_wave.vcd");
    $dumpvars(1, lab5_cpu_wave_tb);
    $dumpvars(1, lab5_cpu_wave_tb.u_cpu);
    $dumpvars(1, lab5_cpu_wave_tb.u_cpu.u_regfile);
    $dumpvars(1, lab5_cpu_wave_tb.u_sram_ctrl);
    $dumpvars(1, lab5_cpu_wave_tb.u_uart);
  end
`endif

  lab5_cpu u_cpu (
      .clk_i(clk),
      .rst_i(rst),
      .pc_o(cpu_pc),
      .wb_cyc_o(cpu_wb_cyc),
      .wb_stb_o(cpu_wb_stb),
      .wb_adr_o(cpu_wb_adr),
      .wb_dat_o(cpu_wb_dat_o),
      .wb_sel_o(cpu_wb_sel),
      .wb_we_o(cpu_wb_we),
      .wb_ack_i(cpu_wb_ack),
      .wb_dat_i(cpu_wb_dat_i)
  );

  wb_mux_3 u_mux (
      .clk(clk),
      .rst(rst),
      .wbm_adr_i(cpu_wb_adr),
      .wbm_dat_i(cpu_wb_dat_o),
      .wbm_dat_o(cpu_wb_dat_i),
      .wbm_we_i(cpu_wb_we),
      .wbm_sel_i(cpu_wb_sel),
      .wbm_stb_i(cpu_wb_stb),
      .wbm_ack_o(cpu_wb_ack),
      .wbm_err_o(),
      .wbm_rty_o(),
      .wbm_cyc_i(cpu_wb_cyc),

      .wbs0_addr(32'h8000_0000),
      .wbs0_addr_msk(32'hFFC0_0000),
      .wbs0_adr_o(wbs0_adr),
      .wbs0_dat_i(wbs0_dat_i),
      .wbs0_dat_o(wbs0_dat_o),
      .wbs0_we_o(wbs0_we),
      .wbs0_sel_o(wbs0_sel),
      .wbs0_stb_o(wbs0_stb),
      .wbs0_ack_i(wbs0_ack),
      .wbs0_err_i(1'b0),
      .wbs0_rty_i(1'b0),
      .wbs0_cyc_o(wbs0_cyc),

      .wbs1_addr(32'h8040_0000),
      .wbs1_addr_msk(32'hFFC0_0000),
      .wbs1_adr_o(),
      .wbs1_dat_i(32'b0),
      .wbs1_dat_o(),
      .wbs1_we_o(),
      .wbs1_sel_o(),
      .wbs1_stb_o(),
      .wbs1_ack_i(1'b0),
      .wbs1_err_i(1'b0),
      .wbs1_rty_i(1'b0),
      .wbs1_cyc_o(),

      .wbs2_addr(32'h1000_0000),
      .wbs2_addr_msk(32'hFFFF_0000),
      .wbs2_adr_o(wbs2_adr),
      .wbs2_dat_i(wbs2_dat_i),
      .wbs2_dat_o(wbs2_dat_o),
      .wbs2_we_o(wbs2_we),
      .wbs2_sel_o(wbs2_sel),
      .wbs2_stb_o(wbs2_stb),
      .wbs2_ack_i(wbs2_ack),
      .wbs2_err_i(1'b0),
      .wbs2_rty_i(1'b0),
      .wbs2_cyc_o(wbs2_cyc)
  );

  sram_controller #(
      .SRAM_ADDR_WIDTH(20),
      .SRAM_DATA_WIDTH(32)
  ) u_sram_ctrl (
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
      .sram_addr(sram_addr),
      .sram_data(sram_data),
      .sram_ce_n(sram_ce_n),
      .sram_oe_n(sram_oe_n),
      .sram_we_n(sram_we_n),
      .sram_be_n(sram_be_n)
  );

  sram_model_lab5 #(.MODE(1)) u_sram (
      .data(sram_data),
      .addr(sram_addr),
      .ce_n(sram_ce_n),
      .oe_n(sram_oe_n),
      .we_n(sram_we_n),
      .be_n(sram_be_n)
  );

  wb_uart_model u_uart (
      .clk(clk),
      .rst(rst),
      .wb_cyc(wbs2_cyc),
      .wb_stb(wbs2_stb),
      .wb_we(wbs2_we),
      .wb_adr(wbs2_adr),
      .wb_dat_i(wbs2_dat_o),
      .wb_sel(wbs2_sel),
      .wb_ack(wbs2_ack),
      .wb_dat_o(wbs2_dat_i),
      .tx_valid(uart_valid),
      .tx_data(uart_data)
  );

  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (rst) begin
      prev_wb_stb <= 1'b0;
    end else begin
      prev_wb_stb <= u_cpu.wb_stb_o;

      if (u_cpu.state == 3'd1)
        $display("t=%0t DECODE: pc=%08h inst=%08h", $time, u_cpu.pc_now, u_cpu.inst);

      if ((u_cpu.state == 3'd2) && u_cpu.branch && u_cpu.zero)
        $display("t=%0t BRANCH TAKEN: pc=%08h imm=%08h target=%08h",
                 $time, u_cpu.pc_now, u_cpu.imm, u_cpu.pc_now + u_cpu.imm);

      if (u_cpu.wb_stb_o && !prev_wb_stb && u_cpu.wb_we_o) begin
        if (u_cpu.wb_adr_o == 32'h8000_0100)
          $display("t=%0t MEM WRITE: pc=%08h inst=%08h addr=%08h data=%08h",
                   $time, u_cpu.pc_now, u_cpu.inst, u_cpu.wb_adr_o, u_cpu.wb_dat_o);
        if (u_cpu.wb_adr_o == 32'h1000_0000)
          $display("t=%0t UART WRITE: pc=%08h inst=%08h data=%08h",
                   $time, u_cpu.pc_now, u_cpu.inst, u_cpu.wb_dat_o);
      end
    end

    if (uart_valid) begin
      captured_uart <= uart_data;
      $display("t=%0t UART VALID: data=%02h", $time, uart_data);
    end
  end

  initial begin
    #40;
    rst = 0;
  end

  initial begin
    #1000;
    $display("TIMEOUT pc=%08h", cpu_pc);
    $finish;
  end

  initial begin
    wait (cpu_pc == 32'h8000_0024);
    wait (u_cpu.wb_stb_o == 1'b1);
    wait (u_cpu.wb_stb_o == 1'b0);
    repeat (5) @(posedge clk);

    if (u_sram.mem[32'h40] !== 32'h0000_0001) begin
      $display("FAIL mem[0x100]=%08h", u_sram.mem[32'h40]);
      errors = errors + 1;
    end

    if (captured_uart !== 8'h41) begin
      $display("FAIL uart=%02h", captured_uart);
      errors = errors + 1;
    end

    if (u_cpu.u_regfile.regs[7] !== 32'h0000_0000) begin
      $display("FAIL skipped t2=%08h", u_cpu.u_regfile.regs[7]);
      errors = errors + 1;
    end

    if (errors == 0) $display("LAB5 WAVE TEST PASSED");
    else $display("LAB5 WAVE TEST FAILED: %0d errors", errors);
    $finish;
  end

endmodule
