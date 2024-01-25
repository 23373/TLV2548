`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:43:15 01/22/2024 
// Design Name: 
// Module Name:    SPI_Driver 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

//             ___     ___     ___     ___     ___     ___     ___     ___     ___     ___
//       |____|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___
//--      ____                                                                             _____
//-- CS       |___________________________________________________________________________|     
//--               ___     ___     ___     ___     ___     ___     ___     ___     ___         _
//-- SCLK ________|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |_______| 
//--      ____________ _______ _______ _______ _______ _______ _______ _______ _______ _________
//-- MOSI ____________X_______X_______X_______X_______X_______X_______X_______X_______X_________
//--      ____ _______ _______ _______ _______ _______ _______ _______ _______ _______ _________
//-- MISO ____X_______X_______X_______X_______X_______X_______X_______X_______X_______X_________

module SPI_Driver #(
    parameter						P_CLK_FREQ  = 100   ,       //MHZ
									P_SCK_FREQ  = 10            
)
(
    input                               i_clk               ,
    input                               i_rst_n             ,

    input   [15:0]                      i_tx_data           ,
    input                               i_tx_en             ,
    output                              o_tx_ready          ,

    output  [11:0]                      o_rx_data           ,
    output                              o_rx_valid          ,

    output                              o_spi_cs            ,
    output                              o_spi_sck           ,
    output                              o_spi_mosi          ,
    input                               i_spi_miso          
    );
//===========================================================
localparam              P_SCK_DIV = P_CLK_FREQ / P_SCK_FREQ ;

reg                                     ro_spi_cs           ;
reg                                     ro_spi_sck          ;
reg                                     ro_spi_mosi         ;
reg                                     ro_rx_valid         ;
reg                                     ro_tx_ready         ;
reg     [29:0]                          ro_rx_data          ;

reg                                     ri_tx_en            ;

reg     [7 :0]                          r_cnt               ;
reg                                     r_cnt_spi           ;
reg     [7 :0]                          r_cnt_bit           ;
reg     [15:0]                          r_send_data         ;

wire                                    w_active            ;
//===========================================================
assign  w_active = i_tx_en && o_tx_ready;
assign  o_spi_cs   = ro_spi_cs          ;
assign  o_spi_sck  = ro_spi_sck         ;
assign  o_spi_mosi = ro_spi_mosi        ;
assign  o_rx_valid = ro_rx_valid        ;
assign  o_tx_ready = ro_tx_ready        ;
assign  o_rx_data  = ro_rx_data[29:18]  ;

//===========================================================
always@(posedge i_clk)
begin
    if(!i_rst_n)
        ri_tx_en <= 'd0;
    else 
        ri_tx_en <= i_tx_en;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_spi_cs <= 'd1;
    else if(i_tx_en && !ri_tx_en)
        ro_spi_cs <= 'd0;
    else if(r_cnt_bit == 30 && r_cnt == P_SCK_DIV / 2 - 1)
        ro_spi_cs <= 'd1;
    else
        ro_spi_cs <= ro_spi_cs; 
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_tx_ready <= 'd1;
    else if(w_active)
        ro_tx_ready <= 'd0;
    else if(ro_spi_cs)
        ro_tx_ready <= 'd1;
    else
        ro_tx_ready <= ro_tx_ready;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        r_cnt <= 'd0;    
    else if(r_cnt == P_SCK_DIV / 2 - 1)
        r_cnt <= 'd0;
    else if(!ro_spi_cs)
        r_cnt <= r_cnt + 'd1;
    else
        r_cnt <= r_cnt;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_spi_sck <= 'd0;
    else if(ro_spi_cs)
        ro_spi_sck <= 'd0;
    else if(r_cnt == P_SCK_DIV / 2 - 1 && r_cnt_bit < 30)
        ro_spi_sck <= ~ro_spi_sck;
    else
        ro_spi_sck <= ro_spi_sck;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        r_send_data <= 'd0;
    else if(w_active)
        r_send_data <= i_tx_data;
    else if(r_cnt_spi && r_cnt == P_SCK_DIV / 2 - 1)
        r_send_data <= r_send_data << 1;
    else
        r_send_data <= r_send_data;
end 

always@(posedge i_clk)
begin
    if(!i_rst_n)
        r_cnt_spi <= 'd0;
    else if(ro_spi_cs)
        r_cnt_spi <= 'd0;
    else if(r_cnt == P_SCK_DIV / 2 - 1 && r_cnt_bit < 30)
        r_cnt_spi <= r_cnt_spi + 'd1;
    else
        r_cnt_spi <= r_cnt_spi;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        r_cnt_bit <= 'd0;
    else if(r_cnt_bit == 30 && r_cnt == P_SCK_DIV / 2 - 1)
        r_cnt_bit <= 'd0;
    else if(r_cnt_spi && r_cnt == P_SCK_DIV / 2 - 1)
        r_cnt_bit <= r_cnt_bit + 'd1;
    else
        r_cnt_bit <= r_cnt_bit;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_spi_mosi <= 'd0;
    else if(w_active)
        ro_spi_mosi <= i_tx_data[15];
    else if(r_cnt_spi && r_cnt == P_SCK_DIV / 2 - 1)
        ro_spi_mosi <= r_send_data[14];
    else
        ro_spi_mosi <= ro_spi_mosi;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_rx_data <= 'd0;
    else if(!r_cnt_spi && r_cnt == P_SCK_DIV / 2 - 1)
        ro_rx_data <= {ro_rx_data[28:0],i_spi_miso};
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_rx_valid <= 'd0;
    else if(r_cnt_bit == 30 && r_cnt == P_SCK_DIV / 2 - 1)
        ro_rx_valid <= 'd1;
    else 
        ro_rx_valid <= 'd0;
end

endmodule
