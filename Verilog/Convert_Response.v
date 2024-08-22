/* Converts PID Response into a time count value */
module Convert_Response(input  wire        CLK,
                        input  wire        RST_N,
                        input  wire        EN,
                        input  wire [11:0] PID_RESPONSE,
                        output reg  [24:0] TIME_VALUE
                       );
  initial TIME_VALUE = 25'd0;
   always@(posedge CLK or negedge RST_N)
    if(!RST_N)
      TIME_VALUE <= 0;
    else if (EN)
      TIME_VALUE <= PID_RESPONSE[10:4] * 25'd457158; //A Response of 63 will lead too 100% on time
    else
      TIME_VALUE <= TIME_VALUE;
  /* always @(EN)
    TIME_VALUE = PID_RESPONSE[10:4] * 25'd450900; */
  
  //assign TIME_VALUE = PID_RESPONSE[10:4] * 25'd450900;
endmodule