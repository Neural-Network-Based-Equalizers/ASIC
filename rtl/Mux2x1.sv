`timescale 1ns / 1ps
// Verilog project: Verilog code for 16-bit MIPS Processor
// Verilog code for 16 bit single cycle MIPS CPU  
module Mux2x1 (
input logic in_0 , in_1 , sel ,  
output logic out 
);

assign out = (sel == 0 )  ? in_0 : in_1 ; 

endmodule 