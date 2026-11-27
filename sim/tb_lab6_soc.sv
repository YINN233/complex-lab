`timescale 1ns / 1ps

module tb_lab6_soc;
  localparam realtime BIT_NS = 1.0e9 / 115200;
  localparam logic [31:0] USER_CODE = 32'h8010_0000;
  localparam logic [31:0] USER_DATA = 32'h8040_0000;
  logic clk = 0, rst = 1, rxd = 1;
  always #50 clk = ~clk;  // 10 MHz, as on the FPGA.

  wire txd;
  wire [31:0] base_data, ext_data;
  wire [19:0] base_addr, ext_addr;
  wire [3:0] base_be_n, ext_be_n;
  wire base_ce_n, base_oe_n, base_we_n;
  wire ext_ce_n, ext_oe_n, ext_we_n;
  string image_dir;
  byte unsigned rx_queue[$];
  logic [31:0] monitor_entries [0:6];  // SIMPLE, performance tests, PUTC, SPIN.
  logic [31:0] lab1_entries [0:2];
  logic [31:0] trap_entries [0:2];  // EBREAK entry, illegal entry, illegal PC.
  bit expect_illegal = 0;
  int illegal_count = 0;

  lab6_soc dut (
      .clk(clk), .rst(rst), .leds(), .txd(txd), .rxd(rxd),
      .base_ram_data(base_data), .base_ram_addr(base_addr), .base_ram_be_n(base_be_n),
      .base_ram_ce_n(base_ce_n), .base_ram_oe_n(base_oe_n), .base_ram_we_n(base_we_n),
      .ext_ram_data(ext_data), .ext_ram_addr(ext_addr), .ext_ram_be_n(ext_be_n),
      .ext_ram_ce_n(ext_ce_n), .ext_ram_oe_n(ext_oe_n), .ext_ram_we_n(ext_we_n)
  );

  sram_model_lab5 base_ram (
      .data(base_data), .addr(base_addr), .ce_n(base_ce_n), .oe_n(base_oe_n),
      .we_n(base_we_n), .be_n(base_be_n)
  );
  sram_model_lab5 ext_ram (
      .data(ext_data), .addr(ext_addr), .ce_n(ext_ce_n), .oe_n(ext_oe_n),
      .we_n(ext_we_n), .be_n(ext_be_n)
  );

  always @(negedge txd) begin : serial_receive
    byte unsigned value;
    if (!rst) begin
      #(BIT_NS / 2);
      if (txd !== 0) $fatal(1, "invalid UART start bit");
      for (int bit_index = 0; bit_index < 8; bit_index++) begin
        #(BIT_NS);
        value[bit_index] = txd;
      end
      #(BIT_NS);
      if (txd !== 1) $fatal(1, "invalid UART stop bit");
      rx_queue.push_back(value);
    end
  end

  task automatic send_byte(input byte unsigned value);
    rxd = 0;
    #(BIT_NS);
    for (int bit_index = 0; bit_index < 8; bit_index++) begin
      rxd = value[bit_index];
      #(BIT_NS);
    end
    rxd = 1;
    #(BIT_NS);
  endtask

  task automatic send_word(input logic [31:0] value);
    for (int lane = 0; lane < 4; lane++) send_byte(value[8*lane +: 8]);
  endtask

  task automatic read_byte(output byte unsigned value);
    while (rx_queue.size() == 0) @(negedge clk);
    value = rx_queue.pop_front();
  endtask

  task automatic expect_byte(input byte unsigned expected);
    byte unsigned actual;
    read_byte(actual);
    if (actual !== expected)
      $fatal(1, "UART expected 0x%02h, got 0x%02h", expected, actual);
  endtask

  task automatic expect_text(input string expected);
    for (int index = 0; index < expected.len(); index++)
      expect_byte(expected[index]);
  endtask

  task automatic expect_word(input logic [31:0] expected);
    for (int lane = 0; lane < 4; lane++) expect_byte(expected[8*lane +: 8]);
  endtask

  task automatic monitor_upload(input string image_name);
    logic [31:0] words[$];
    logic [31:0] word_value;
    int file;
    file = $fopen({image_dir, "/", image_name, ".mem"}, "r");
    if (file == 0) $fatal(1, "unable to load user program %s", image_name);
    while ($fscanf(file, "%h", word_value) == 1) words.push_back(word_value);
    $fclose(file);
    if (words.size() == 0) $fatal(1, "user program is empty");
    send_byte("A");
    send_word(USER_CODE);
    send_word(4 * words.size());
    foreach (words[index]) send_word(words[index]);

    // D is sent immediately after A, as it can be in Term.
    send_byte("D");
    send_word(USER_CODE);
    send_word(4 * words.size());
    foreach (words[index]) expect_word(words[index]);
  endtask

  task automatic monitor_go(input logic [31:0] entry);
    send_byte("G");
    send_word(entry);
    expect_byte(8'h06);
  endtask

  task automatic monitor_dump(input logic [31:0] address, input int count);
    send_byte("D");
    send_word(address);
    send_word(count);
  endtask

  task automatic expect_register(input int wanted, input logic [31:0] expected);
    logic [31:0] reg_value;
    byte unsigned value;
    send_byte("R");
    for (int reg_index = 1; reg_index < 32; reg_index++) begin
      for (int lane = 0; lane < 4; lane++) begin
        read_byte(value);
        reg_value[8*lane +: 8] = value;
      end
      if (reg_index == wanted && reg_value !== expected)
        $fatal(1, "R x%0d expected %h, got %h", wanted, expected, reg_value);
    end
  endtask

  task automatic check_monitor_tests;
    monitor_go(monitor_entries[0]);
    expect_byte(8'h07);
    expect_register(30, 1);
    $display("LAB6 MONITOR UTEST_SIMPLE PASS");

    for (int index = 1; index <= 4; index++) begin
      monitor_go(monitor_entries[index]);
      expect_byte(8'h07);
      case (index)
        1: expect_register(28, 2);  // 1PTB: t3 is 2.
        2: expect_register(7, 3);   // 2DCT: t2 is 3 after three iterations.
        3: expect_register(5, 0);   // 3CCT: t0 is 0.
        4: expect_register(6, 0);   // 4MDCT: t1 is 0.
      endcase
    end
    $display("LAB6 MONITOR PERFORMANCE SMOKE (3 iterations) PASS");
  endtask

  task automatic check_monitor_ver2;
    monitor_go(monitor_entries[5]);  // Official UTEST_PUTC: two ECALLs and a return.
    expect_text("OK");
    expect_byte(8'h07);
    expect_register(10, 32'h4b);
    $display("LAB6 MONITOR VER2 USER ECALL AND RETURN PASS");

    monitor_upload("ver2_traps");
    monitor_go(trap_entries[0]);
    expect_byte(8'h07);
    monitor_dump(USER_DATA + 'h120, 4);
    expect_word('h135);  // The store before EBREAK commits, the following one does not.
    $display("LAB6 MONITOR VER2 PRECISE EBREAK PASS");

    monitor_go(monitor_entries[6]);  // Official UTEST_SPIN never returns on its own.
    expect_byte(8'h81);
    monitor_dump(USER_DATA + 'h120, 4);
    expect_word('h135);
    $display("LAB6 MONITOR VER2 TIMER TIMEOUT AND COMMAND RECOVERY PASS");

    expect_illegal = 1;
    monitor_go(trap_entries[1]);
    expect_byte(8'h80);
    expect_word(trap_entries[2]);
    expect_word(2);
    expect_word(32'h0000_007b);
    expect_illegal = 0;
    if (illegal_count != 1) $fatal(1, "expected one illegal instruction trap, got %0d", illegal_count);

    expect_text("MONITOR for RISC-V - initialized.");
    monitor_dump(USER_DATA + 'h124, 4);
    expect_word('h246);
    monitor_go(monitor_entries[0]);
    expect_byte(8'h07);
    expect_register(30, 1);
    $display("LAB6 MONITOR VER2 PRECISE ILLEGAL TRAP AND REBOOT PASS");
  endtask

  initial begin : timeout
    if ($test$plusargs("VER2")) #1200ms;  // Include the original 10,000,000-tick timeout.
    else #150ms;
    $fatal(1, "SoC timed out at PC %h", dut.cpu_pc);
  end

  always @(posedge clk) if (!rst) begin
    if (dut.cpu_illegal) begin
      if (!expect_illegal) $fatal(1, "illegal instruction, fetch PC %h", dut.cpu_pc);
      illegal_count++;
    end
    if (dut.wbs2_cyc && dut.wbs2_stb && dut.wbs2_adr == 32'h1000_0005 &&
        dut.wbs2_sel !== 4'b0010)
      $fatal(1, "UART status access did not select byte lane 1");
  end

  initial begin : test_sequence
    int first_term, second_term, next_term;
    bit ver2;
    string monitor_image;
    if (!$value$plusargs("IMAGES=%s", image_dir)) $fatal(1, "missing IMAGES");
    ver2 = $test$plusargs("VER2");

    #1;
    if ($test$plusargs("SUM")) $readmemh({image_dir, "/sum.mem"}, base_ram.mem);
    else if ($test$plusargs("UART_IRQ")) $readmemh({image_dir, "/uart_irq.mem"}, base_ram.mem);
    else begin
      monitor_image = ver2 ? "monitor-ver2" : "monitor";
      $readmemh({image_dir, "/", monitor_image, ".mem"}, base_ram.mem);
      $readmemh({image_dir, "/", monitor_image, "-entries.mem"}, monitor_entries, 0, ver2 ? 6 : 4);
      $readmemh({image_dir, "/lab1-entries.mem"}, lab1_entries);
      if (ver2) $readmemh({image_dir, "/ver2_traps-entries.mem"}, trap_entries);
      // Shorten only the leading LUI of each long benchmark in simulated SRAM.
      // Keep the shipped monitor binary, benchmark bodies and call paths intact.
      for (int index = 1; index <= 4; index++) begin
        if ((base_ram.mem[monitor_entries[index][21:2]] & 32'h00000fff) !== 32'h000002b7)
          $fatal(1, "unexpected loop-counter instruction in UTEST %0d", index);
        base_ram.mem[monitor_entries[index][21:2]] = 32'h00300293;  // addi t0, zero, 3
      end
    end
    repeat (5) @(negedge clk);
    rst = 0;

    if ($test$plusargs("SUM")) begin
      expect_text("done!");
      if (base_ram.mem[64] !== 32'd5050) $fatal(1, "incorrect sum");
      #(12 * BIT_NS);
      if (rx_queue.size() != 0) $fatal(1, "unexpected repeated UART write");
      $display("LAB6 SOC SUM PASS");
    end else if ($test$plusargs("UART_IRQ")) begin
      expect_byte("R");
      send_byte("Z");
      expect_byte("A");
      send_byte("m");
      expect_byte("P");
      $display("LAB6 SOC UART IRQ PASS");
    end else begin
      expect_text("MONITOR for RISC-V - initialized.");
      check_monitor_tests();
      monitor_upload("lab1");

      monitor_go(lab1_entries[0]);
      expect_byte(8'h07);
      monitor_dump(USER_DATA, 40);
      first_term = 1;
      second_term = 1;
      repeat (10) begin
        expect_word(first_term);
        next_term = first_term + second_term;
        first_term = second_term;
        second_term = next_term;
      end

      monitor_go(lab1_entries[1]);
      expect_byte(8'h07);
      monitor_dump(USER_DATA, 8);
      expect_word(32'h6c83_12d0);
      expect_word(32'h0000_0168);

      monitor_go(lab1_entries[2]);
      for (int ascii = 'h21; ascii <= 'h7e; ascii++) expect_byte(byte'(ascii));
      expect_byte(8'h07);
      $display("LAB6 MONITOR LAB1 PASS");

      monitor_upload("grp56");
      monitor_go(USER_CODE);
      expect_byte(8'h07);
      monitor_dump(USER_DATA + 'h100, 16);
      expect_word(32'h8000_0000);
      expect_word(0);
      expect_word(32);
      expect_word(31);
      $display("LAB6 MONITOR GRP56 PASS");
      if (ver2) begin
        check_monitor_ver2();
        $display("LAB6 SOC MONITOR VER2 PASS");
      end else $display("LAB6 SOC MONITOR PASS");
    end
    $finish;
  end
endmodule
