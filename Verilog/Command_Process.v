module Command_Process(input  wire        CLK,
                       input  wire        RST_N,
                       input  wire [15:0] COMMAND,
                       output reg  [13:0] SETPOINT,
                       output reg  [13:0] PROPORTIONAL,
                       output reg  [13:0] INTEGRAL,
                       output reg  [13:0] DERIVATIVE
                      );
  initial begin
    SETPOINT     = 14'b0100101_0000000; //37 Degrees
    PROPORTIONAL = 14'b0100000_1001100; //32.59492
    INTEGRAL     = 14'b0000000_0000000; //0
    DERIVATIVE   = 14'b0000000_0000000;
  end
  always @(posedge CLK or negedge RST_N)
    if(!RST_N) begin
      SETPOINT     <= 14'b0100101_0000000;
      PROPORTIONAL <= 14'b0100000_1001100;
      INTEGRAL     <= 14'b0000000_0000000;
      DERIVATIVE   <= 14'b0000000_0000000;
    end
    else
      case(COMMAND[15:14])
        2'b00:  if(COMMAND[13:0] >= 14'b00110111000000 && COMMAND[13:0] <= 14'b11001000000000)
                  SETPOINT   <= COMMAND[13:0];
                else
                  SETPOINT   <= SETPOINT;
        2'b01:  PROPORTIONAL <= COMMAND[13:0];
        2'b10:  INTEGRAL     <= COMMAND[13:0];
        2'b11:  DERIVATIVE   <= COMMAND[13:0];
      endcase
endmodule