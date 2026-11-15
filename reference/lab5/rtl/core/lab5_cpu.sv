`timescale 1ns / 1ps

`default_nettype none

module lab5_cpu (
    input  wire        clk_i,
    input  wire        rst_i,

    output logic [31:0] pc_o,

    output logic        wb_cyc_o,
    output logic        wb_stb_o,
    output logic [31:0] wb_adr_o,
    output logic [31:0] wb_dat_o,
    output logic [ 3:0] wb_sel_o,
    output logic        wb_we_o,
    input  wire        wb_ack_i,
    input  wire [31:0] wb_dat_i
);

  typedef enum logic [2:0] {
    S_FETCH,
    S_DECODE,
    S_EXEC,
    S_MEM_READ,
    S_MEM_WRITE,
    S_WB
  } state_t;

  state_t state = S_FETCH;

  logic [31:0] pc;
  logic [31:0] pc_now;
  logic [31:0] inst;

  logic [31:0] rs1_val;
  logic [31:0] rs2_val;
  logic [31:0] operand1;
  logic [31:0] operand2;
  logic [31:0] store_data;
  logic [31:0] imm;
  logic [31:0] alu_y;
  logic [31:0] alu_result;
  logic [31:0] addr;
  logic [31:0] mem_data;
  logic [31:0] wb_data;
  logic [ 7:0] load_byte;

  logic [ 4:0] rs1;
  logic [ 4:0] rs2;
  logic [ 4:0] rd;

  logic [ 2:0] alu_op;
  logic [ 2:0] imm_type;
  logic        alu_b_sel;
  logic        wb_src;
  logic        branch;
  logic        mem_read;
  logic        mem_write;
  logic        mem_size;
  logic        reg_we;
  logic        zero;

  logic        req_valid;
  logic        req_we;
  logic [31:0] req_addr;
  logic [31:0] req_wdata;
  logic [ 3:0] req_sel;
  logic        resp_valid;
  logic [31:0] resp_rdata;

  assign pc_o = pc;

  decoder u_decoder (
      .inst     (inst),
      .reg_we   (reg_we),
      .mem_read (mem_read),
      .mem_write(mem_write),
      .alu_op   (alu_op),
      .alu_b_sel(alu_b_sel),
      .wb_src   (wb_src),
      .branch   (branch),
      .mem_size (mem_size),
      .imm_type (imm_type),
      .rs1      (rs1),
      .rs2      (rs2),
      .rd       (rd)
  );

  imm_gen u_imm_gen (
      .inst    (inst),
      .imm_type(imm_type),
      .imm     (imm)
  );

  regfile32 u_regfile (
      .clk    (clk_i),
      .rst    (rst_i),
      .we     (reg_we && (state == S_WB)),
      .waddr  (rd),
      .wdata  (wb_data),
      .raddr_a(rs1),
      .rdata_a(rs1_val),
      .raddr_b(rs2),
      .rdata_b(rs2_val)
  );

  alu32 u_alu (
      .a   (operand1),
      .b   (operand2),
      .op  (alu_op),
      .y   (alu_y),
      .zero(zero)
  );

  wb_master u_wb_master (
      .clk_i       (clk_i),
      .rst_i       (rst_i),
      .req_valid_i (req_valid),
      .req_we_i    (req_we),
      .req_addr_i  (req_addr),
      .req_wdata_i (req_wdata),
      .req_sel_i   (req_sel),
      .resp_valid_o(resp_valid),
      .resp_rdata_o(resp_rdata),
      .wb_cyc_o    (wb_cyc_o),
      .wb_stb_o    (wb_stb_o),
      .wb_adr_o    (wb_adr_o),
      .wb_dat_o    (wb_dat_o),
      .wb_sel_o    (wb_sel_o),
      .wb_we_o     (wb_we_o),
      .wb_ack_i    (wb_ack_i),
      .wb_dat_i    (wb_dat_i)
  );

  always_comb begin
    load_byte = mem_data[7:0];
    case (addr[1:0])
      2'd1: load_byte = mem_data[15:8];
      2'd2: load_byte = mem_data[23:16];
      2'd3: load_byte = mem_data[31:24];
      default: load_byte = mem_data[7:0];
    endcase

    if (wb_src) wb_data = {{24{load_byte[7]}}, load_byte};
    else wb_data = alu_result;
  end

  always_comb begin
    req_valid = 1'b0;
    req_we    = 1'b0;
    req_addr  = 32'b0;
    req_wdata = 32'b0;
    req_sel   = 4'b1111;

    case (state)
      S_FETCH: begin
        req_valid = 1'b1;
        req_we    = 1'b0;
        req_addr  = pc;
        req_sel   = 4'b1111;
      end

      S_MEM_READ: begin
        req_valid = 1'b1;
        req_we    = 1'b0;
        req_addr  = addr;
        req_sel   = 4'b1111;
      end

      S_MEM_WRITE: begin
        req_valid = 1'b1;
        req_we    = 1'b1;
        req_addr  = addr;
        if (mem_size) begin
          req_sel   = 4'b1111;
          req_wdata = store_data;
        end else begin
          req_sel   = 4'b0001 << addr[1:0];
          req_wdata = store_data << {addr[1:0], 3'b000};
        end
      end

      default: ;
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      state      <= S_FETCH;
      pc         <= 32'h8000_0000;
      pc_now     <= 32'b0;
      inst       <= 32'b0;
      operand1   <= 32'b0;
      operand2   <= 32'b0;
      store_data <= 32'b0;
      alu_result <= 32'b0;
      addr       <= 32'b0;
      mem_data   <= 32'b0;
    end else begin
      case (state)
        S_FETCH: begin
          if (resp_valid) begin
            inst   <= resp_rdata;
            pc_now <= pc;
            pc     <= pc + 32'd4;
            state  <= S_DECODE;
          end
        end

        S_DECODE: begin
          operand1   <= rs1_val;
          operand2   <= alu_b_sel ? imm : rs2_val;
          store_data <= rs2_val;
          state      <= S_EXEC;
        end

        S_EXEC: begin
          alu_result <= alu_y;
          addr       <= alu_y;

          if (branch) begin
            if (zero) pc <= pc_now + imm;
            state <= S_FETCH;
          end else if (mem_read) begin
            state <= S_MEM_READ;
          end else if (mem_write) begin
            state <= S_MEM_WRITE;
          end else begin
            state <= S_WB;
          end
        end

        S_MEM_READ: begin
          if (resp_valid) begin
            mem_data <= resp_rdata;
            state    <= S_WB;
          end
        end

        S_MEM_WRITE: begin
          if (resp_valid) state <= S_FETCH;
        end

        S_WB: begin
          state <= S_FETCH;
        end

        default: state <= S_FETCH;
      endcase
    end
  end

endmodule

`default_nettype wire
