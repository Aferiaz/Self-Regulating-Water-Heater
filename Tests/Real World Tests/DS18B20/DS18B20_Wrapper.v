module DS18B20_Wrapper (input        CLOCK_27A,
                        input  [3:0] PB,
                        inout        DS_WIRE,
                        output [6:0] HEX0, HEX1, HEX2, HEX3,
                        output [9:0] LEDR
                       );
  function [6:0] bcdto7seg; //(bcd);
    input [3:0] bcd;
    case (bcd)
      0:  bcdto7seg = 7'b1000000; //gfedcba
      1:  bcdto7seg = 7'b1111001; 
      2:  bcdto7seg = 7'b0100100; 
      3:  bcdto7seg = 7'b0110000; 
      4:  bcdto7seg = 7'b0011001; 
      5:  bcdto7seg = 7'b0010010; 
      6:  bcdto7seg = 7'b0000010; 
      7:  bcdto7seg = 7'b1111000; 
      8:  bcdto7seg = 7'b0000000; 
      9:  bcdto7seg = 7'b0010000; 
      10: bcdto7seg = 7'b0001000; 
      11: bcdto7seg = 7'b0000011; 
      12: bcdto7seg = 7'b1000110; 
      13: bcdto7seg = 7'b0100001; 
      14: bcdto7seg = 7'b0000110; 
      15: bcdto7seg = 7'b0001110; 
      default:  bcdto7seg = 7'b1111111;
    endcase
  endfunction

  wire [15:0] temperature;
  wire [8:0]  bcd;
  
  DS18B20_Master Master ( .CLK(CLOCK_27A),
                          .RST_N(PB[0]),
                          .DS18B20_WIRE(DS_WIRE),
                          .TEMPERATURE(temperature),
                          .STATE_LED(LEDR[8:0])
                        );
  // Bits 10 to 4 contain the data for temperature in decimal form                      
  bin2bcd        #(.W(7))
  Timer_Minute    (.BINARY(temperature[10:4]),
                   .BCD(bcd[8:0])
                  );
  
  assign HEX0 = bcdto7seg(bcd[3:0]);
  assign HEX1 = bcdto7seg(bcd[7:4]); 
  assign HEX2 = bcdto7seg({3'b0,bcd[8]});                 
  assign HEX3 = bcdto7seg(4'b0);

endmodule