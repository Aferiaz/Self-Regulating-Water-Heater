module bin2bcd #( parameter W = 10)
                ( input  wire [W-1:0]         BINARY,
                  output reg  [W+((W-4)/3):0] BCD
                );
  integer i,j;
  always @(BINARY) begin
    for(i = 0; i <= (W+((W-4)/3)); i = i+1)
      BCD[i] = 0;
    BCD[W-1:0] = BINARY;
    for(i = 0; i <= W-4; i = i+1)
      for(j = 0; j <= i/3; j = j+1)
        if (BCD[W-i+4*j -: 4] > 4)
          BCD[W-i+4*j -: 4] = BCD[W-i+4*j -: 4] + 4'd3;
  end
endmodule