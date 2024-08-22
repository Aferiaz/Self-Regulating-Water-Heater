module TimeProportion(input  wire        CLK,
                      input  wire        RST_N,
                      input  wire [24:0] VALUE,
                      output wire        TRIGGER
                     );
  // Sampling Period Clock, expected to have 1.0667 second
  reg [24:0] period;
  initial period = 25'd28_800_900;
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      //Place as the maximum value to not start a trigger
      period <= 25'd28_800_900;
    else
      period <= (period < 25'd28_800_900) ? period + 1'b1 : 25'd0;
  
  assign TRIGGER = (VALUE > period);
  
endmodule