module tb_SPI #(parameter WIDTH = 12);
reg CLK, SC0;
reg MOSI;
reg MISOflag; // to be sent triggered when data is ready to be sent from slave to master
reg [WIDTH-1:0] DATA_MISO;
wire MISO;
wire [WIDTH-1:0] DATA_MOSI;
wire dflag;

initial
begin
	MOSI = 0;	
	MISOflag = 0;
	CLK = 0;
	SC0 = 1;
end

SPI #(.WIDTH(WIDTH))
UUT (
	.CLK(CLK), 
	.MOSI(MOSI), 
	.MISO(MISO), 
	.SC0(SC0), 
	.DATA_MOSI(DATA_MOSI), 
	.DATA_MISO(DATA_MISO), 
	.dflag(dflag), 
	.MISOflag(MISOflag)
);

always #10 CLK <= ~CLK;

initial
begin
    #10 CLK = 0;
	#35 SC0 = 0;
	#20 MOSI = 1;
	DATA_MISO = 12'b010011_001100;
	#20 MOSI = 0;
	MISOflag = 1;
	#20 MOSI = 1;
	#20 MOSI = 0;
	#20 MOSI = 1;
	#20 MOSI = 0;
	#20 MOSI = 0;
	#20 MOSI = 1;
	#20 MOSI = 0;
	#20 MOSI = 1;
	#20 MOSI = 0;
	#20 MOSI = 1;
	DATA_MISO = 12'b110101_101011;
	#20 MOSI = 1;
	#20 MOSI = 1;
	#20 MOSI = 1;
	#20 MOSI = 1;
	#20 MOSI = 1;
	#20 MOSI = 0;
	#20 MOSI = 0;
	#20 MOSI = 0;
	#20 MOSI = 0;
	#20 MOSI = 1;
	#20 MOSI = 1;
	#20 MOSI = 1;
	#100 $stop;
end
endmodule