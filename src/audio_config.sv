// This module configures the wolfson codec.
`define rom_size 6'd8

module audio_config (
   input clk,    // 50 MHz.
   input reset,
   inout i2c_data,
   output i2c_clk
);

reg [10:0] COUNTER_500;
reg [15:0] ROM[`rom_size:0];
reg [15:0] DATA_A;
reg [5:0] address;
reg SDO;
reg SCLK;
reg [23:0] SD;
reg [5:0] SD_COUNTER;
reg ACK1,ACK2,ACK3;

reg done;
wire [6:0] volume;
wire CLOCK_500 = COUNTER_500[9];
wire [23:0]DATA={8'h34,DATA_A};	
wire GO =((address <= `rom_size) && (done==1))? COUNTER_500[10]:1;

assign volume = 7'b1111001;    //111 1001 = 0 dB, which is the power-on value.
assign i2c_clk = SCLK | ( ((SD_COUNTER >= 4) & (SD_COUNTER <= 30))? ~CLOCK_500 :0 );
assign i2c_data = SDO ? 1'bz : 0;

always @(posedge reset or posedge done) 
	begin
		if ( reset )
			begin
				address = 0;
			end
		else if (address <= `rom_size)
				begin
					address = address + 1;
				end
	end

always @(posedge done) 
    begin

        ROM[4] = {7'd0,		 9'b000010111};         //
        ROM[5] = {7'd1,		 9'b000010111};         //
        ROM[6] = {7'd2,		 2'b00, volume[6:0]};   //
        ROM[7] = {7'd3,		 2'b00, volume[6:0]};   // sound vol
        ROM[2] = {7'd4, 1'b0, 8'b0000_1_010};       // all default (bypass on (b3), adc to line-in (b2) )
        ROM[0] = {7'd6, 1'b0, 8'b01101010};         // poweroff clockout (b6), internal osc. (b5), DAC (b3), microphone (b1)
        ROM[1] = {7'd7, 1'b0, 8'b01000001};         // b6 = 1 (master mode), b3,b2 = 00 (16-bits format), b1,b0 = 01 (msb, left-justified)
        ROM[3] = {7'd8, 1'b0, 8'b00001110};         // SR (b5-2) = 0011, BOSR=1, normal mode. So 96KHz ADC, 18,432 MCLK freq.
        //ROM[4]= 16'h1e00;                         // reset
        ROM[`rom_size]= {7'd9, 8'b00000000, 1'b1};  // active
        DATA_A=ROM[address];
    end

always @(posedge clk )   // 50 MHz input.
	begin
		COUNTER_500 = COUNTER_500 + 1;
	end

//==============================I2C COUNTER====================================
always @(posedge reset or posedge CLOCK_500 ) 
	begin
		if ( reset )
			begin
				SD_COUNTER = 6'b111111;
			end
		else begin
				if (GO == 0)
					begin
						SD_COUNTER = 0;
					end
				else begin
						if (SD_COUNTER < 6'b111111)
							begin
								SD_COUNTER = SD_COUNTER+1;
							end	
					 end		
			 end
	end
//----------- I2C interface ------------
always @(posedge reset or posedge CLOCK_500 ) 
	begin
		if ( reset ) 
			begin 
				SCLK = 1;
				SDO  = 1; 
				ACK1 = 0;
				ACK2 = 0;
				ACK3 = 0; 
				done  = 1; 
			end
		else
			case (SD_COUNTER)
					6'd0  : begin 
								ACK1 = 0 ;
								ACK2 = 0 ;
								ACK3 = 0 ; 
								done  = 0 ; 
								SDO  = 1 ; 
								SCLK = 1 ;
							end
					//=========start===========
					6'd1  : begin 
								SD  = DATA;
								SDO = 0;
							end
							
					6'd2  : 	SCLK = 0;
					//======SLAVE ADDR=========
					6'd3  : 	SDO = SD[23];
					6'd4  : 	SDO = SD[22];
					6'd5  : 	SDO = SD[21];
					6'd6  : 	SDO = SD[20];
					6'd7  : 	SDO = SD[19];
					6'd8  : 	SDO = SD[18];
					6'd9  :	SDO = SD[17];
					6'd10 : 	SDO = SD[16];	
					6'd11 : 	SDO = 1'b1;//ACK

					//========SUB ADDR==========
					6'd12  : begin 
								SDO  = SD[15]; 
								ACK1 = i2c_data; 
							 end
					6'd13  : 	SDO = SD[14];
					6'd14  : 	SDO = SD[13];
					6'd15  : 	SDO = SD[12];
					6'd16  : 	SDO = SD[11];
					6'd17  : 	SDO = SD[10];
					6'd18  : 	SDO = SD[9];
					6'd19  : 	SDO = SD[8];	
					6'd20  : 	SDO = 1'b1;//ACK

					//===========DATA============
					6'd21  : begin 
								SDO  = SD[7]; 
								ACK2 = i2c_data; 
							 end
					6'd22  : 	SDO = SD[6];
					6'd23  : 	SDO = SD[5];
					6'd24  : 	SDO = SD[4];
					6'd25  : 	SDO = SD[3];
					6'd26  : 	SDO = SD[2];
					6'd27  : 	SDO = SD[1];
					6'd28  : 	SDO = SD[0];	
					6'd29  : 	SDO = 1'b1;//ACK

					//stop
					6'd30 : begin 
								SDO  = 1'b0;	
								SCLK = 1'b0; 
								ACK3 = i2c_data; 
							end	
					6'd31 : 	SCLK = 1'b1; 
					6'd32 : begin 
								SDO = 1'b1; 
								done = 1; 
							end 
			endcase
	end
	
endmodule 