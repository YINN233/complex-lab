`timescale 1ns / 1ps

module tb_wb_master;

  logic        clk = 0;
  logic        rst;

  logic        req_valid;
  logic        req_we;
  logic [31:0] req_addr;
  logic [31:0] req_wdata;
  logic [ 3:0] req_sel;
  logic        resp_valid;
  logic [31:0] resp_rdata;

  logic        wb_cyc;
  logic        wb_stb;
  logic [31:0] wb_adr;
  logic [31:0] wb_dat_o;
  logic [ 3:0] wb_sel;
  logic        wb_we;
  logic        wb_ack;
  logic [31:0] wb_dat_i;

  integer errors = 0;

  wb_master dut (
      .clk_i       (clk),
      .rst_i       (rst),
      .req_valid_i (req_valid),
      .req_we_i    (req_we),
      .req_addr_i  (req_addr),
      .req_wdata_i (req_wdata),
      .req_sel_i   (req_sel),
      .resp_valid_o(resp_valid),
      .resp_rdata_o(resp_rdata),
      .wb_cyc_o    (wb_cyc),
      .wb_stb_o    (wb_stb),
      .wb_adr_o    (wb_adr),
      .wb_dat_o    (wb_dat_o),
      .wb_sel_o    (wb_sel),
      .wb_we_o     (wb_we),
      .wb_ack_i    (wb_ack),
      .wb_dat_i    (wb_dat_i)
  );

  typedef enum logic [1:0] {
    S_IDLE,
    S_WAIT,
    S_ACK
  } slave_state_t;

  slave_state_t slave_state = S_IDLE;
  logic [31:0] lat_addr;
  logic [31:0] lat_data;
  logic [ 3:0] lat_sel;
  integer      write_count = 0;

  always_ff @(posedge clk) begin
    if (rst) begin
      slave_state <= S_IDLE;
      wb_ack      <= 1'b0;
      lat_addr    <= 32'b0;
      lat_data    <= 32'b0;
      lat_sel     <= 4'b0;
      write_count <= 0;
    end else begin
      case (slave_state)
        S_IDLE: begin
          wb_ack <= 1'b0;
          if (wb_cyc && wb_stb) begin
            lat_addr <= wb_adr;
            lat_data <= wb_dat_o;
            lat_sel  <= wb_sel;
            if (wb_we) write_count <= write_count + 1;
            slave_state <= S_WAIT;
          end
        end

        S_WAIT: begin
          wb_ack      <= 1'b1;
          slave_state <= S_ACK;
        end

        S_ACK: begin
          wb_ack      <= 1'b0;
          slave_state <= S_IDLE;
        end

        default: slave_state <= S_IDLE;
      endcase
    end
  end

  assign wb_dat_i = wb_we ? 32'b0 : 32'hDEAD_BEEF;

  always #5 clk = ~clk;

  task do_read;
    input [31:0] addr;
    begin
      @(posedge clk);
      req_valid <= 1'b1;
      req_we    <= 1'b0;
      req_addr  <= addr;
      req_sel   <= 4'b1111;
      wait (resp_valid === 1'b1);
      #1;
      if (resp_rdata !== 32'hDEAD_BEEF) begin
        $display("FAIL read rdata=%08h", resp_rdata);
        errors = errors + 1;
      end
      req_valid <= 1'b0;
      @(posedge clk);
    end
  endtask

  task do_write;
    input [31:0] addr;
    input [31:0] data;
    input [ 3:0] sel;
    begin
      @(posedge clk);
      req_valid <= 1'b1;
      req_we    <= 1'b1;
      req_addr  <= addr;
      req_wdata <= data;
      req_sel   <= sel;
      wait (resp_valid === 1'b1);
      #1;
      req_valid <= 1'b0;
      @(posedge clk);
    end
  endtask

  initial begin
    rst = 1; req_valid = 0; req_we = 0; req_addr = 0; req_wdata = 0; req_sel = 0;
    repeat (3) @(posedge clk);
    rst = 0;
    @(posedge clk);

    do_read(32'h8000_0000);
    if (lat_addr !== 32'h8000_0000) begin
      $display("FAIL read addr=%08h", lat_addr);
      errors = errors + 1;
    end

    do_write(32'h1000_0000, 32'h0000_0055, 4'b0001);
    if (write_count !== 1 || lat_addr !== 32'h1000_0000 || lat_data !== 32'h0000_0055 || lat_sel !== 4'b0001) begin
      $display("FAIL write1 count=%0d addr=%08h data=%08h sel=%b", write_count, lat_addr, lat_data, lat_sel);
      errors = errors + 1;
    end

    do_write(32'h1000_0000, 32'h0000_0055, 4'b0001);
    if (write_count !== 2) begin
      $display("FAIL write2 count=%0d", write_count);
      errors = errors + 1;
    end

    if (errors == 0) $display("WB_MASTER TEST PASSED");
    else $display("WB_MASTER TEST FAILED: %0d errors", errors);
    $finish;
  end

endmodule
