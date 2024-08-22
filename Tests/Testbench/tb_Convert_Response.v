module tb_Convert_Response;
  reg  [11:0] pid_response;
  wire [24:0] time_value;
  reg         clk;
  reg         rst_n;
  reg         en;
  Convert_Response Converted (.CLK(clk),
                              .RST_N(rst_n),
                              .EN(en),
                              .PID_RESPONSE(pid_response),
                              .TIME_VALUE(time_value)
                             );
                  
  always #50 clk = ~clk;
  
  initial begin
    initialize();
    run_no_en(12'b1000_0000_1010);
    run_no_en(12'b0000_0001_1010);
    run_no_en(12'b1000_0010_1010);
    run_en(12'b1000_0000_1010);
    run_en(12'b0000_0001_1010);
    run_en(12'b1000_0010_1010);
    run_en(12'b0000_0100_1010);
    run_en(12'b1000_1000_1010);
    run_en(12'b0001_0000_1010);
    run_en(12'b1010_0000_1010);
    run_en(12'b0100_0000_1010);
    run_en(12'b1000_0000_1010);
    repeat(5) @(negedge clk);
    $finish;
  end
  
  task initialize;
  begin
    clk          = 0;
    rst_n        = 1;
    en           = 0;
    pid_response = 0;
    @(negedge clk);
    rst_n = 0;
    repeat(5) @(negedge clk);
    rst_n = 1;
  end
  endtask
  task run_no_en (input [11:0] value);
  begin
    @(negedge clk);
    pid_response = value;
    @(negedge clk);
  end
  endtask
  
  task run_en (input [11:0] value);
  begin
    @(negedge clk);
    en = 1;
    pid_response = value;
    @(negedge clk);
    en = 0;
  end
  endtask
  
endmodule