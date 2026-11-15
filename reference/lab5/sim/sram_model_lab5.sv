module sram_model_lab5 #(
    parameter ADDR_WIDTH = 20,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 1048576,
    parameter MODE = 0
) (
    inout  wire [DATA_WIDTH-1:0] data,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire                  ce_n,
    input  wire                  oe_n,
    input  wire                  we_n,
    input  wire [3:0]            be_n
);

  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
  wire read_en = !ce_n && !oe_n && we_n;

  initial begin
    if (MODE == 0) begin
      mem[0]  = 32'h00000293;
      mem[1]  = 32'h06400313;
      mem[2]  = 32'h00000393;
      mem[3]  = 32'h00128293;
      mem[4]  = 32'h007283b3;
      mem[5]  = 32'h00628463;
      mem[6]  = 32'hfe000ae3;
      mem[7]  = 32'h800002b7;
      mem[8]  = 32'h1072a023;
      mem[9]  = 32'h100002b7;
      mem[10] = 32'h00528303;
      mem[11] = 32'h02037313;
      mem[12] = 32'hfe030ce3;
      mem[13] = 32'h06400513;
      mem[14] = 32'h00a28023;
      mem[15] = 32'h00528303;
      mem[16] = 32'h02037313;
      mem[17] = 32'hfe030ce3;
      mem[18] = 32'h06f00513;
      mem[19] = 32'h00a28023;
      mem[20] = 32'h00528303;
      mem[21] = 32'h02037313;
      mem[22] = 32'hfe030ce3;
      mem[23] = 32'h06e00513;
      mem[24] = 32'h00a28023;
      mem[25] = 32'h00528303;
      mem[26] = 32'h02037313;
      mem[27] = 32'hfe030ce3;
      mem[28] = 32'h06500513;
      mem[29] = 32'h00a28023;
      mem[30] = 32'h00528303;
      mem[31] = 32'h02037313;
      mem[32] = 32'hfe030ce3;
      mem[33] = 32'h02100513;
      mem[34] = 32'h00a28023;
      mem[35] = 32'h00000063;
    end else if (MODE == 1) begin
      mem[0] = 32'h00100293;
      mem[1] = 32'h00100313;
      mem[2] = 32'h00628463;
      mem[3] = 32'h7ff00393;
      mem[4] = 32'h800002b7;
      mem[5] = 32'h1062a023;
      mem[6] = 32'h100002b7;
      mem[7] = 32'h04100513;
      mem[8] = 32'h00a28023;
      mem[9] = 32'h00000063;
    end else begin
      mem[0]  = 32'h800002b7;
      mem[1]  = 32'h1002a023;
      mem[2]  = 32'h08000313;
      mem[3]  = 32'h106280a3;
      mem[4]  = 32'h10128383;
      mem[5]  = 32'h1072a223;
      mem[6]  = 32'h07f00e13;
      mem[7]  = 32'h11c28123;
      mem[8]  = 32'h10228e83;
      mem[9]  = 32'h11d2a423;
      mem[10] = 32'h00000063;
    end
  end

  assign #10 data = read_en ? mem[addr] : {DATA_WIDTH{1'bz}};

  always @(negedge we_n) begin
    if (!ce_n) begin
      if (!be_n[0]) mem[addr][7:0]   <= data[7:0];
      if (!be_n[1]) mem[addr][15:8]  <= data[15:8];
      if (!be_n[2]) mem[addr][23:16] <= data[23:16];
      if (!be_n[3]) mem[addr][31:24] <= data[31:24];
    end
  end

endmodule
