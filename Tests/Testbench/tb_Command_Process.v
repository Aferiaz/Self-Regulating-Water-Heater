module tb_Command_Process;
  reg         clk;
  reg         rst_n;
  reg  [15:0] command;
  wire [13:0] setpoint;
  wire [13:0] proportional;
  wire [13:0] integral;
  wire [13:0] derivative;
  Command_Process Process (.CLK(clk),
                           .RST_N(rst_n),
                           .COMMAND(command),
                           .SETPOINT(setpoint),
                           .PROPORTIONAL(proportional),
                           .INTEGRAL(integral),
                           .DERIVATIVE(derivative)
                          );
                  
  always #50 clk = ~clk;
  
  initial begin
    clk = 0;
    rst_n = 1;
    command = 16'd0;
    @(negedge clk);
    rst_n = 0;
    @(negedge clk);
    rst_n = 1;
    @(negedge clk);
    command = 16'd0;
    @(negedge clk);
    command = 16'b00_00110111000000; // Check Minimum if it works
    @(negedge clk);
    command = 16'b00_00110110000000; // Check Less than Minimum
    @(negedge clk);
    command = 16'b00_11111111111111; // Check Greater than Maximum
    @(negedge clk);
    command = 16'b00_11001000000000; // Check Maximum
    @(negedge clk);
    command = 16'b00_01001010000000; //Check Random
    @(negedge clk);
    command = 16'b01_10000000000000;
    @(negedge clk);
    command = 16'b10_10000000000000;
    @(negedge clk);
    command = 16'b11_10000000000000;
    @(negedge clk);
    $finish;
  end
endmodule