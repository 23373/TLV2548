`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:42:14 01/22/2024 
// Design Name: 
// Module Name:    TLV2548_Driver 
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


module TLV2548_Driver #(
    parameter                           P_SAMPLE_TIME = 200     ,   // 通道切换时间间隔     
                            P_REG_CFG = 12'b0_0_0_00_11_00_0_00     
)           
(
    input                               i_clk               ,
    input                               i_rst_n             ,

    //adc bus
    input                               i_adc_int           ,
    output                              o_adc_cs            ,   
    output                              o_adc_sck           ,
    output                              o_adc_mosi          ,
    input                               i_adc_miso          ,

    //8-channel output
    output      [11:0]                  o_vtemp_A           , 	//channel_1  
    output      [11:0]                  o_vtemp_B           ,	//channel_2  
    output      [11:0]                  o_vtemp_C           ,	//channel_3  
    output      [11:0]                  o_vtemp_D           ,	//channel_4  
    output      [11:0]                  o_vtemp_E           ,   //channel_5                
    output      [11:0]                  o_vtemp_F           ,	//channel_6  
    output      [11:0]                  o_vtemp_G           ,	//channel_7  
    output      [11:0]                  o_vtemp_H           ,	//channel_8  

    output                              o_valid       			//data valid      
    );
/*
=============================================================
                    define  localparam
=============================================================
*/

localparam                              ST_IDLE     = 0     ,	
                                        ST_RESET    = 1     ,
                                        ST_REG_CFG  = 2     ,
                                        ST_CH_A     = 3     ,
                                        ST_CH_B     = 4     ,     
                                        ST_CH_C     = 5     ,
                                        ST_CH_D     = 6     ,
                                        ST_CH_E     = 7     ,
                                        ST_CH_F     = 8     ,
                                        ST_CH_G     = 9     ,
                                        ST_CH_H     = 10    ,
                                        ST_INT      = 11    ,
                                        ST_READ_A   = 12    ,
                                        ST_READ_B   = 13    ,
                                        ST_READ_C   = 14    ,
                                        ST_READ_D   = 15    ,
                                        ST_READ_E   = 16    ,
                                        ST_READ_F   = 17    ,
                                        ST_READ_G   = 18    ,
                                        ST_READ_H   = 19    ;

localparam                     P_WAIT_CH = P_SAMPLE_TIME / 10;
/*
=============================================================
                    define  variable
=============================================================
*/
reg         [11:0]                  ro_vtemp_A          ;
reg         [11:0]                  ro_vtemp_B          ;
reg         [11:0]                  ro_vtemp_C          ;
reg         [11:0]                  ro_vtemp_D          ;
reg         [11:0]                  ro_vtemp_E          ;
reg         [11:0]                  ro_vtemp_F          ;
reg         [11:0]                  ro_vtemp_G          ;
reg         [11:0]                  ro_vtemp_H          ;
reg                                 ro_valid            ;

reg         [7 :0]                  c_state , n_state   ;

reg         [15:0]                  r_cnt_wait          ;
reg         [7 :0]                  r_cnt_req           ;

reg                                 ro_tx_ready         ;

reg         [15:0]                  r_tx_data           ;
reg                                 r_tx_en             ;

wire                                w_ready_edge        ;

wire                                wo_tx_ready         ;
wire        [11:0]                  wo_rx_data          ;
wire                                wo_rx_valid         ;

//spi module
SPI_Driver #(
    .P_CLK_FREQ                     (100            ),       //MHZ
    .P_SCK_FREQ                     (10             )        
)
SPI_Driver_u0
(
    .i_clk                          (i_clk          ),
    .i_rst_n                        (i_rst_n        ),
    .i_tx_data                      (r_tx_data      ),
    .i_tx_en                        (r_tx_en        ),
    .o_tx_ready                     (wo_tx_ready    ),
    .o_rx_data                      (wo_rx_data     ),
    .o_rx_valid                     (wo_rx_valid    ),
    .o_spi_cs                       (o_adc_cs       ),
    .o_spi_sck                      (o_adc_sck      ),
    .o_spi_mosi                     (o_adc_mosi     ),
    .i_spi_miso                     (i_adc_miso     )
    );
//===========================================================
assign  o_vtemp_A    = ro_vtemp_A                           ;
assign  o_vtemp_B    = ro_vtemp_B                           ;
assign  o_vtemp_C    = ro_vtemp_C                           ;
assign  o_vtemp_D    = ro_vtemp_D                           ;
assign  o_vtemp_E    = ro_vtemp_E                           ;
assign  o_vtemp_F    = ro_vtemp_F                           ;
assign  o_vtemp_G    = ro_vtemp_G                           ;
assign  o_vtemp_H    = ro_vtemp_H                           ;
assign  o_valid      = ro_valid                             ;
assign  w_ready_edge = !ro_tx_ready && wo_tx_ready          ;

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_tx_ready <= 'd1;
    else 
        ro_tx_ready <= wo_tx_ready;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        c_state <= ST_IDLE;
    else 
        c_state <= n_state;
end

always@(*)
begin
    if(!i_rst_n)
        n_state = ST_IDLE;
    else 
        case(c_state)
            ST_IDLE    : n_state = ST_RESET;
            ST_RESET   : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_REG_CFG : ST_RESET    ;
            ST_REG_CFG : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_CH_A    : ST_REG_CFG  ;
            ST_CH_A    : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_CH_B    : ST_CH_A     ; 
            ST_CH_B    : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_CH_C    : ST_CH_B     ; 
            ST_CH_C    : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_CH_D    : ST_CH_C     ; 
            ST_CH_D    : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_CH_E    : ST_CH_D     ; 
            ST_CH_E    : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_CH_F    : ST_CH_E     ; 
            ST_CH_F    : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_CH_G    : ST_CH_F     ; 
            ST_CH_G    : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_CH_H    : ST_CH_G     ; 
            ST_CH_H    : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_INT     : ST_CH_H     ; 
            ST_INT     : n_state = (i_adc_int == 0 		       ) ? ST_READ_A  : ST_INT      ; 
            ST_READ_A  : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_READ_B  : ST_READ_A   ; 
            ST_READ_B  : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_READ_C  : ST_READ_B   ; 
            ST_READ_C  : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_READ_D  : ST_READ_C   ; 
            ST_READ_D  : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_READ_E  : ST_READ_D   ; 
            ST_READ_E  : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_READ_F  : ST_READ_E   ; 
            ST_READ_F  : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_READ_G  : ST_READ_F   ; 
            ST_READ_G  : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_READ_H  : ST_READ_G   ; 
            ST_READ_H  : n_state = (r_cnt_wait == P_WAIT_CH - 1) ? ST_CH_A    : ST_READ_H   ;
            default    : n_state = ST_IDLE;
        endcase
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        r_cnt_wait <= 'd0;
    else if(c_state != n_state)
        r_cnt_wait <= 'd0;
    else if(w_ready_edge || r_cnt_wait)
        r_cnt_wait <= r_cnt_wait + 'd1;
    else
        r_cnt_wait <= r_cnt_wait;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        r_cnt_req <= 'd0;
    else if(c_state != n_state)
        r_cnt_req <= 'd0;
    else if(r_cnt_req == 2)
        r_cnt_req <= r_cnt_req;
    else if(c_state != ST_IDLE || c_state != ST_INT)
        r_cnt_req <= r_cnt_req + 'd1;
    else 
        r_cnt_req <= r_cnt_req;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        r_tx_en <= 'd0;
    else if(r_cnt_req == 1)
        r_tx_en <= 'd1;
    else
        r_tx_en <= 'd0;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        r_tx_data <= 'd0;
    else if(r_cnt_req == 1)
            case(c_state)
                ST_RESET   : r_tx_data <= 16'hA0_00; 
                ST_REG_CFG : r_tx_data <= {4'b1010,P_REG_CFG}; 
                ST_CH_A    : r_tx_data <= 16'h00_00; 
                ST_CH_B    : r_tx_data <= 16'h10_00;
                ST_CH_C    : r_tx_data <= 16'h20_00;
                ST_CH_D    : r_tx_data <= 16'h30_00;
                ST_CH_E    : r_tx_data <= 16'h40_00;
                ST_CH_F    : r_tx_data <= 16'h50_00;
                ST_CH_G    : r_tx_data <= 16'h60_00;
                ST_CH_H    : r_tx_data <= 16'h70_00;
                ST_READ_A  : r_tx_data <= 16'hE0_00;
                ST_READ_B  : r_tx_data <= 16'hE0_00;
                ST_READ_C  : r_tx_data <= 16'hE0_00;
                ST_READ_D  : r_tx_data <= 16'hE0_00;
                ST_READ_E  : r_tx_data <= 16'hE0_00;
                ST_READ_F  : r_tx_data <= 16'hE0_00;
                ST_READ_G  : r_tx_data <= 16'hE0_00;
                ST_READ_H  : r_tx_data <= 16'hE0_00;
                default    : r_tx_data <= 'd0;
            endcase
    else
        r_tx_data <= 'd0;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_vtemp_A <= 'd0;
    else if(wo_rx_valid && c_state == ST_READ_A)
        ro_vtemp_A <= wo_rx_data;
    else 
        ro_vtemp_A <= ro_vtemp_A;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_vtemp_B <= 'd0;
    else if(wo_rx_valid && c_state == ST_READ_B)
        ro_vtemp_B <= wo_rx_data;
    else 
        ro_vtemp_B <= ro_vtemp_B;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_vtemp_C <= 'd0;
    else if(wo_rx_valid && c_state == ST_READ_C)
        ro_vtemp_C <= wo_rx_data;
    else 
        ro_vtemp_C <= ro_vtemp_C;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_vtemp_D <= 'd0;
    else if(wo_rx_valid && c_state == ST_READ_D)
        ro_vtemp_D <= wo_rx_data;
    else 
        ro_vtemp_D <= ro_vtemp_D;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_vtemp_E <= 'd0;
    else if(wo_rx_valid && c_state == ST_READ_E)
        ro_vtemp_E <= wo_rx_data;
    else 
        ro_vtemp_E <= ro_vtemp_E;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_vtemp_F <= 'd0;
    else if(wo_rx_valid && c_state == ST_READ_F)
        ro_vtemp_F <= wo_rx_data;
    else 
        ro_vtemp_F <= ro_vtemp_F;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_vtemp_G <= 'd0;
    else if(wo_rx_valid && c_state == ST_READ_G)
        ro_vtemp_G <= wo_rx_data;
    else 
        ro_vtemp_G <= ro_vtemp_G;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_vtemp_H <= 'd0;
    else if(wo_rx_valid && c_state == ST_READ_H)
        ro_vtemp_H <= wo_rx_data;
    else 
        ro_vtemp_H <= ro_vtemp_H;
end

always@(posedge i_clk)
begin
    if(!i_rst_n)
        ro_valid <= 'd0;
    else if(wo_rx_valid && c_state == ST_READ_H)
        ro_valid <= 'd1;
    else
        ro_valid <= 'd0;
end

endmodule
