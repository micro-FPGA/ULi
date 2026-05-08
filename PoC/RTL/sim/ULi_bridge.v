`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MicroFPGA UG(h)
// Engineer: Antti Lukats 
// 
// Create Date: 07.05.2026 14:02:20
// Design Name: 
// Module Name: ULi_bridge
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ULi_bridge(
    input m_o,
    input m_t,
    output m_i,
    input s_o,
    input s_t,
    output s_i,
    output ULi
    );
    
assign s_i = s_t ? s_o : m_o;
assign m_i = m_t ? m_o : s_o;

assign ULi = s_t ? s_o : m_o;
  
    
endmodule
