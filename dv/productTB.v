`timescale 1ps / 1ps 
module producttb;

  reg clk;
  reg reset;
  reg [15:0]A;
  reg [15:0]B;
  reg MAC_START;
  
  wire [39:0] MAC_ACC;
  wire [4:0] bit_counter;
  wire mac_start_latch;
  wire mac_done;
  
  product uut_product(.clk(clk),.reset(reset),.A(A),.B(B),.MAC_START(MAC_START),.MAC_ACC(MAC_ACC),.bit_counter(bit_counter),.mac_start_latch(mac_start_latch),.mac_done(mac_done));
  always
  begin 
          #4 clk=!clk; 
  end 
  initial 
     begin 
       clk=1'b0;
       reset=1'b1;
       $dumpfile("product.vcd"); 
       $dumpvars;
       $monitor($time, "clk=%b, reset=%b, A=%b, B=%b, MAC_START=%b, MAC_ACC=%b, bit_counter=%b, mac_start_latch=%b, mac_done=%b", clk, reset, A, B, MAC_START, MAC_ACC, bit_counter, mac_start_latch, mac_done);
       A = 16'b0;
       B = 16'b0;
       MAC_START = 1'b0;
       #5 reset = 1'b0;
       #1 MAC_START = 1'b1;
       #2 A = 16'b1000001000110101;
       #2 B = 16'b1101100100000011;
       #184 MAC_START = 1'b0;
       #2 A = 16'b0101011011001110;
       #2 B = 16'b0101011011001110;
       #1 MAC_START = 1'b1;
       #32
       $finish;
       
     end 
endmodule