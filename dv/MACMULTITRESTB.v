`timescale 1ps / 1ps 
module mactb;

  reg clk;
  reg reset;
  reg [31:0]MAC_INA;
  reg [31:0]MAC_INB;
  reg [7:0]MAC_CTRL;
  
  wire [15:0] MAC_OUT;
  wire IRQ_MAC;
  
  mac uut_mac(.clk(clk),.reset(reset),.MAC_INA(MAC_INA),.MAC_INB(MAC_INB),.MAC_CTRL(MAC_CTRL),.MAC_OUT(MAC_OUT),.IRQ_MAC(IRQ_MAC));
  always
  begin 
          #4 clk=!clk; 
  end 
  initial 
     begin 
       clk=1'b0;
       reset=1'b1;
       $dumpfile("macmulti.vcd"); 
       $dumpvars;
       $monitor($time, "clk=%b, reset=%b, MAC_INA=%b, MAC_INB=%b, MAC_CTRL=%b, MAC_OUT=%b, IRQ_MAC=%b", clk, reset, MAC_INA, MAC_INB, MAC_CTRL, MAC_OUT, IRQ_MAC);
       MAC_INA = 32'b0;
       MAC_INB = 32'b0;
       MAC_CTRL = 8'b10000000;
       #5 reset = 1'b0;
       #5 MAC_CTRL = 8'b10001101;
       #3 MAC_INA = 32'b1010110110011101000001000110101;
       #1 MAC_INB = 32'b1010110110011101101100100000011;
       #1 MAC_CTRL = 8'b10001111;
       #184
       $finish;
       
     end 
endmodule