//CLK - every process starts with the clock input from the SPI Master
//SC0 - Chip select must be set to low for the slave to be triggered
//MOSI - Master Out Slave In - Input mode (MSB is the first bit that is accepted)
//MISO - Master In Slave Out - Output mode (LSB is the first bit that is sent)
//MISO and MOSI are parallel processes
module SPI #(parameter WIDTH = 12)(CLK, MOSI, MISO, SC0, DATA_MOSI, DATA_MISO, dflag, MISOflag);
input CLK, SC0;
input MOSI;
input MISOflag; // to be sent triggered when data is ready to be sent from slave to master
input [WIDTH-1:0] DATA_MISO;
output reg MISO;
output reg [WIDTH-1:0] DATA_MOSI;
output reg dflag;
reg [WIDTH-1:0] MISO_bitcounter, MOSI_bitcounter;
reg MOSIreg, MISO_flag_edge;
reg [WIDTH-1:0] MISOreg; // data should be stored in a register to avoid having data glitches while sending midway in a number

initial
begin
	MOSI_bitcounter = 0;
	MISO_bitcounter = 0;
end

//Purpose: Getting MOSI bits
//Only 1 clock cycle where DATA is valid every (WIDTH) bits
always @(posedge CLK)
begin
	MOSIreg <= MOSI;
	if(SC0 == 0)
	begin
		DATA_MOSI <= DATA_MOSI << 1;
		DATA_MOSI[0] <= MOSI;
		if(MOSI_bitcounter >= WIDTH)
		begin
			MOSI_bitcounter <= 1;
			dflag <= 1; // flag for data that is ready or just simply transmit it
		end
		else
		begin
			dflag <= 0;
			MOSI_bitcounter <= MOSI_bitcounter + 1;
		end
	end
	else
	begin
		DATA_MOSI <= 0; // clear
	end
end

//Purpose: Sending MISO bits
//Data validity like dflag should be placed in ESP32 code
//Recommendation: if MISO bits are not enough, make the ESP32 see it as invalid
//For the ESP32 to detect that MISO will start, 1 bit would turn high for 1 clock cycle then start transmitting the data
always @(posedge CLK)
begin
	MISO_flag_edge <= MISOflag;
	if(MISOflag == ~MISO_flag_edge)
	begin
		MISOreg <= DATA_MISO;
		MISO <= 1;
	end
	else if(MISOflag == 1) //this flag should be set to high whenever data is to be transmitted
	begin
		MISO <= MISOreg[0];
		MISOreg <= MISOreg >> 1;
		if(MISO_bitcounter >= (WIDTH-1))
		begin
			MISOreg <= DATA_MISO;
			MISO_bitcounter <= 0;
		end
		else
		begin
			MISO_bitcounter <= MISO_bitcounter + 1;
		end
	end
	else
	begin
		MISO <= 0; // clear;
	end
end

endmodule