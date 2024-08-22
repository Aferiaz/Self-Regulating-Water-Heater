module SPI_Remaster #(parameter WIDTH = 16)(input  wire CLK,
                                            input  wire RST_N,
                                            //Between ESP32
                                            input  wire SCK,
                                            input  wire MOSI,
                                            input  wire SS,
                                            output wire MISO,
                                            //Inside FPGA
                                            input  wire [WIDTH-1:0] WRITE_DATA,
                                            output reg  [WIDTH-1:0] READ_DATA
                                            );
  
  /* Wires and Registers */
  // SPI Clock
  reg  [2:0] sck_sample;
  wire       sck_rising_edge;
  wire       sck_falling_edge;
  
  // Slave Select
  reg  [2:0] ss_sample;
  wire       ss;
  
  // Master In Slave Out
  reg  [2:0] mosi_sample;
  wire       mosi;
  
  // SPI Bit Counter
  reg  [4:0] read_cnt;
  reg  [4:0] write_cnt;
  
  // Receiving Process
  reg [15:0] receive_data;
  
  // Sending Process
  reg [15:0] send_data;
  reg [15:0] write_data;
  
  /* Initial Values */
  initial begin
    sck_sample   =  3'd0;
    ss_sample    =  3'd0;
    mosi_sample  =  2'd0;
    read_cnt     =  5'd0;
    write_cnt    =  5'd0;
    receive_data = 16'd0;
    send_data    = 16'd0;
  end
  
  
  /* Clock Sampling and  Edge Detection */
  // SPI Clock
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      sck_sample <= 3'd0;
    else
      sck_sample <= {sck_sample[1:0], SCK};
    
  assign sck_rising_edge  = (sck_sample[2:1] == 2'b10);
  assign sck_falling_edge = (sck_sample[2:1] == 2'b01);
  
  // Slave Select
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      ss_sample <= 3'd0;
    else
      ss_sample <= {ss_sample[1:0], SS};
  
  assign ss = !ss_sample[1];
  
  // Master Out Slave In
  initial mosi_sample = 3'b0;
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      mosi_sample <= 3'd0;
    else
      mosi_sample <= {mosi_sample[1:0], MOSI};
  
  assign mosi = mosi_sample[1];
  

  /* Receiving Process */
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
     read_cnt <= 5'd0;
    else if (ss)
      if(sck_rising_edge)
        read_cnt <= read_cnt + 1'b1;
      else
        read_cnt <= read_cnt;
    else
      read_cnt <= 5'd0;
      
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      receive_data <= 16'd0;
    else if(sck_falling_edge)
      receive_data <= {receive_data[14:0], mosi};
    else
      receive_data <= receive_data;
  
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      READ_DATA <= 16'd0;
    else if (read_cnt == 5'd15 && ss && sck_rising_edge)
      READ_DATA <= receive_data;
    else
      READ_DATA <= READ_DATA;
  
  
  /* Sending Process */
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
     write_cnt <= 5'd0;
    else if (ss)
      if(sck_falling_edge)
        write_cnt <= write_cnt + 1'b1;
      else
        write_cnt <= write_cnt;
    else
      write_cnt <= 5'd0;   
      
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      send_data <= 16'd0;
    else if (ss)
      if(write_cnt == 5'd0)
        send_data <= WRITE_DATA;
      else if(sck_rising_edge)
        send_data <= send_data << 1;
      else
        send_data <= send_data;
    else
      send_data <= 16'd0;

  assign MISO = send_data[15];

endmodule
