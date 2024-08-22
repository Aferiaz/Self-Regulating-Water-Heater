module SPI_Remaster_Wrapper(input        CLOCK_27A,
                   input  [3:0] PB,
                   input        SCK,
                   input        MOSI,
                   input        SS,
                   output       MISO,
                   output [6:0] HEX0, HEX1, HEX2, HEX3
                  );
  
  wire [15:0] command;
  
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
      default:  bcdto7seg = 7'b1111111;  //blank				
    endcase
  endfunction
  
  SPI_Remaster Controller(.CLK(CLOCK_27A),
                          .RST_N(PB[0]),
                          .SCK(SCK),
                          .MOSI(MOSI),
                          .SS(SS),
                          .MISO(MISO),
                          .WRITE_DATA(16'hbeef),
                          .READ_DATA(command)
                         );
                         
  assign HEX0 = bcdto7seg(command[3:0]);
  assign HEX1 = bcdto7seg(command[7:4]);
  assign HEX2 = bcdto7seg(command[11:8]);
  assign HEX3 = bcdto7seg(command[15:12]);
endmodule