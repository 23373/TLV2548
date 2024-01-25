`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:00:35 01/22/2024 
// Design Name: 
// Module Name:    TLV2548 
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
module TLV2548(
    input                               i_clk           ,
    
    output       [5:0]                  o_fpga_oen      ,
    //adc bus
    input                               i_adc_int       ,	// EOC
    output                              o_adc_cs        ,	// CS
    output                              o_adc_sck       ,	// SCK
    output                              o_adc_mosi      ,   // SDO
    input                               i_adc_miso          // SDI
    );
/*
=========================================================
                    define  variable
=========================================================
*/
wire                                    w_clk_100M      ;
wire                                    w_clk_0         ;
wire                                    w_locked        ;

wire    [11:0]                          wo_vtemp_A      ; 
wire    [11:0]                          wo_vtemp_B      ; 
wire    [11:0]                          wo_vtemp_C      ; 
wire    [11:0]                          wo_vtemp_D      ; 
wire    [11:0]                          wo_vtemp_E      ; 
wire    [11:0]                          wo_vtemp_F      ; 
wire    [11:0]                          wo_vtemp_G      ; 
wire    [11:0]                          wo_vtemp_H      ; 
wire                                    wo_valid        ;

wire                                    w_rst_n         ;

wire    [35:0]                          CONTROL0        ;

// Enable level conversion chip Oen 1-6
assign  o_fpga_oen = 6'b00_0000;  

// clk
DCM_BASE #(
    .CLKDV_DIVIDE(2.0), // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
                        // 7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
    .CLKFX_DIVIDE(1), // Can be any integer from 1 to 32
    .CLKFX_MULTIPLY(2), // Can be any integer from 2 to 32
    .CLKIN_DIVIDE_BY_2("FALSE"), // TRUE/FALSE to enable CLKIN divide by two feature
    .CLKIN_PERIOD(20.0), // Specify period of input clock in ns from 1.25 to 1000.00
    .CLKOUT_PHASE_SHIFT("NONE"), // Specify phase shift mode of NONE or FIXED
    .CLK_FEEDBACK("1X"), // Specify clock feedback of NONE, 1X or 2X
    .DCM_PERFORMANCE_MODE("MAX_SPEED"), // Can be MAX_SPEED or MAX_RANGE
    .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
                                          //   an integer from 0 to 15
    .DFS_FREQUENCY_MODE("LOW"), // LOW or HIGH frequency mode for frequency synthesis
    .DLL_FREQUENCY_MODE("LOW"), // LOW, HIGH, or HIGH_SER frequency mode for DLL
    .DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
    .FACTORY_JF(16'hf0f0), // FACTORY JF value suggested to be set to 16'hf0f0
    .PHASE_SHIFT(0), // Amount of fixed phase shift from -255 to 1023
    .STARTUP_WAIT("FALSE") // Delay configuration DONE until DCM LOCK, TRUE/FALSE
) 
DCM_BASE_inst (
    .CLK0(w_clk_0),         // 0 degree DCM CLK output
    .CLK180(),     // 180 degree DCM CLK output
    .CLK270(),     // 270 degree DCM CLK output
    .CLK2X(w_clk_100M),       // 2X DCM CLK output
    .CLK2X180(), // 2X, 180 degree DCM CLK out
    .CLK90(),       // 90 degree DCM CLK output
    .CLKDV(),       // Divided DCM CLK out (CLKDV_DIVIDE)
    .CLKFX(),       // DCM CLK synthesis out (M/D)
    .CLKFX180(), // 180 degree CLK synthesis out
    .LOCKED(w_locked),     // DCM LOCK status output
    .CLKFB(w_clk_0),       // DCM clock feedback
    .CLKIN(i_clk),       // Clock input (from IBUFG, BUFG or DCM)
    .RST(0)            // DCM asynchronous reset input
   );

RST_GEN #(
    .P_RST_CYCLE                        (100                ) 
)
RST_GEN_u0
(
    .i_clk                              (w_clk_100M         ),
    .o_rst_n                            (w_rst_n            )  
);

//adc
TLV2548_Driver #(
    .P_SAMPLE_TIME                      (200    			)  ,   	// Channel switching time interval     
    .P_REG_CFG                          (12'b0000_0110_0000	)  		// ADC register configuration  
)
TLV2548_Driver_u0
(
    .i_clk                              (w_clk_100M         ),
    .i_rst_n                            (w_rst_n            ),
    //adc bus
    .i_adc_int                          (i_adc_int          ),
    .o_adc_cs                           (o_adc_cs           ),
    .o_adc_sck                          (o_adc_sck          ),
    .o_adc_mosi                         (o_adc_mosi         ),
    .i_adc_miso                         (i_adc_miso         ),
    //8-channel output
    .o_vtemp_A                          (wo_vtemp_A         ),   
    .o_vtemp_B                          (wo_vtemp_B         ),
    .o_vtemp_C                          (wo_vtemp_C         ),
    .o_vtemp_D                          (wo_vtemp_D         ),
    .o_vtemp_E                          (wo_vtemp_E         ),                 
    .o_vtemp_F                          (wo_vtemp_F         ),
    .o_vtemp_G                          (wo_vtemp_G         ),
    .o_vtemp_H                          (wo_vtemp_H         ),
    .o_valid                            (wo_valid           )            
    );


//ila
ILA_ICON ICON (
    .CONTROL0                           (CONTROL0           ) // INOUT BUS [35:0]
);

ILA_ILA ILA (
    .CONTROL                            (CONTROL0           ), // INOUT BUS [35:0]
    .CLK                                (w_clk_100M         ), // IN
    .TRIG0                              (i_adc_int          ), // IN BUS [0:0]
    .TRIG1                              (o_adc_cs           ), // IN BUS [0:0]
    .TRIG2                              (o_adc_sck          ), // IN BUS [0:0]
    .TRIG3                              (o_adc_mosi         ), // IN BUS [0:0]
    .TRIG4                              (i_adc_miso         ), // IN BUS [0:0]
    .TRIG5                              (wo_valid           ) // IN BUS [0:0]
);

endmodule
