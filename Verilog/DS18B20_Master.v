module DS18B20_Master(input  wire        CLK, //Assume using 27 MHz48
                      input  wire        RST_N,
                      inout  wire        DS18B20_WIRE,
                      output reg  [15:0] TEMPERATURE
                      //output reg  [ 9:0] STATE_LED
                     );
  /* States */
  localparam PREPARE             = 4'd1,
             INITIALIZE_REQUEST  = 4'd2,
             INITIALIZE_RESPONSE = 4'd3,
             TEMP_CONV_REQUEST   = 4'd4,
             TEMP_CONV_WAIT      = 4'd5,
             TEMP_CONV_DONE      = 4'd6,
             READ_REQUEST        = 4'd7,
             READ_DATA           = 4'd8,
             READ_DONE           = 4'd9;
  /* DS18B20 Commands */
  localparam ROM_SKIP     = 8'hcc,
             CONVERT_TEMP = 8'h44,
             READ_TEMP    = 8'hbe;
  
  /* Timing */
  localparam PREPARE_TIME     = 12'd2700,     //100  uS
             INIT_REQ_TIME    = 15'd18954,    //702  uS
             INIT_REQ_TIME_2  = 15'd54,       //2    uS
             INIT_RESP_TIME_1 = 14'd2700,     //100  uS
             INIT_RESP_TIME_2 = 14'd12960,    //480  uS
             INIT_RESP_TIME_3 = 14'd405,      //15   uS
             INIT_RESP_TIME_4 = 14'd8640,     //320  uS
             WRITE_TIME_TOTAL = 11'd1674,     //62   uS
             WRITE_TIME_TRIG  = 11'd54,       //2   uS
             WRITE_TIME_HIGH  = 11'd1620,     //60   uS
             WRITE_TIME_LOW   = 11'd81,       //3    uS
             READ_TIME_TOTAL  = 11'd1674,     //62   uS 
             READ_TIME_TRIG   = 11'd324,      //12   uS
             READ_TIME_HIGH   = 11'd1620,     //60   uS
             READ_TIME_LOW    = 11'd54,       //2    uS
             WAIT_TIME        = 17'd81000,    //3000 uS
             DONE_TIME        = 29'd13500000;  //29'd27000000; //1 Second
             
  
  /* Wires and Registers */
  // Prepare State
  reg [11:0] prepare_cnt;
  // Wait State
  reg [16:0] wait_cnt;
  // Done State
  reg [28:0] done_cnt;
  // Initialize Request State
  reg [14:0] init_req_cnt;
  // Initialize Response State
  reg [13:0] init_resp_cnt;
  reg        dsb18b20_response;
  reg        temp_conv_requested;
  // Write
  reg [10:0] write_cnt;
  reg [15:0] command;
  reg [ 4:0] write_bit_cnt;
  reg        write_done;
  reg        write_data;
  // Read
  reg [10:0] read_cnt;
  reg [ 4:0] read_bit_cnt;
  reg [15:0] read_data;
  reg        read_done;
  // Output
  reg ds18b20_wire;
  // State Machine
  reg [3:0] state;
  reg [3:0] next_state;
  
  /* State Machine */
  initial begin
    state      = PREPARE;
    next_state = PREPARE;
  end

  always@(posedge CLK or negedge RST_N)
    if(!RST_N)
      state <= PREPARE;
    else
      state <= next_state;
      
  always@(posedge CLK or negedge RST_N)
    //NOTE: Should the cnt be using ==? I think it should use >= to lessen errors
    if(!RST_N)
      next_state <= PREPARE;
    else
      case(state)
        PREPARE:              if(prepare_cnt >= PREPARE_TIME)
                                next_state <= INITIALIZE_REQUEST;
                              else
                                next_state <= PREPARE;
        INITIALIZE_REQUEST:   if(init_req_cnt >= INIT_REQ_TIME)
                                next_state <= INITIALIZE_RESPONSE;
                              else
                                next_state <= INITIALIZE_REQUEST;
        INITIALIZE_RESPONSE:  if(init_resp_cnt >= INIT_RESP_TIME_2 && dsb18b20_response)
                                next_state <= PREPARE;
                              else if(init_resp_cnt >= INIT_RESP_TIME_2 && !dsb18b20_response && !temp_conv_requested)
                                next_state <= TEMP_CONV_REQUEST;
                              else if(init_resp_cnt >= INIT_RESP_TIME_2 && !dsb18b20_response && temp_conv_requested)
                                next_state <= READ_REQUEST;
                              else
                                next_state <= INITIALIZE_RESPONSE;
        TEMP_CONV_REQUEST:    if(write_done)
                                next_state <= TEMP_CONV_WAIT;
                              else
                                next_state <= TEMP_CONV_REQUEST;
        TEMP_CONV_WAIT:       if(wait_cnt  >= WAIT_TIME)
                                next_state <= TEMP_CONV_DONE;
                              else
                                next_state <= TEMP_CONV_WAIT;
        TEMP_CONV_DONE:       next_state <= PREPARE;
        READ_REQUEST:         if(write_done)
                                next_state <= READ_DATA;
                              else
                                next_state <= READ_REQUEST;
        READ_DATA:            if(read_done)
                                next_state <= READ_DONE;
                              else
                                next_state <= READ_DATA;
        READ_DONE:            if(done_cnt >= DONE_TIME)
                                next_state <= PREPARE;
                              else
                                next_state <= READ_DONE;
        default:              next_state <= PREPARE;
      endcase
  
  /* Preparation State */
  // Counter
  initial prepare_cnt = 12'b0;
  always @ (posedge CLK or negedge RST_N)
    if(!RST_N)
      prepare_cnt <= 12'b0;
    else if (state == PREPARE)
      prepare_cnt <= prepare_cnt + 12'b1;
    else
      prepare_cnt <= 12'b0;
  
  /* Wait State */
  initial wait_cnt = 17'b0;
  always @ (posedge CLK or negedge RST_N)
    if(!RST_N)
      wait_cnt <= 17'b0;
    else if (state == TEMP_CONV_WAIT)
      wait_cnt <= wait_cnt + 1'b1;
    else
      wait_cnt <= 17'b0;
  
  /* Done State */
  // NOTE: Fix Bit Type
  initial done_cnt = 24'b0;
  always @ (posedge CLK or negedge RST_N)
    if(!RST_N)
      done_cnt <= 24'b0;
    else if (state == READ_DONE)
      done_cnt <= done_cnt + 1'b1;
    else
      done_cnt <= 24'b0;
  
  /* Initialize Request State */
  // Counter
  initial init_req_cnt = 15'b0;
  always@ (posedge CLK or negedge RST_N)
    if(!RST_N)
      init_req_cnt <= 15'b0;
    else if (state == INITIALIZE_REQUEST)
      init_req_cnt <= init_req_cnt + 1'b1;
    else
      init_req_cnt <= 15'b0;
  
  /* Inititalize Response State */
  // Counter
  initial init_resp_cnt = 14'b0;
  always@ (posedge CLK or negedge RST_N)
    if(!RST_N)
      init_resp_cnt <= 14'b0;
    else if (state == INITIALIZE_RESPONSE)
      init_resp_cnt <= init_resp_cnt + 1'b1;
    else
      init_resp_cnt <= 14'b0;
  // dsb18b20 Response
  initial dsb18b20_response = 1'b0;
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      dsb18b20_response <= 1'b0;
    else if (state == INITIALIZE_RESPONSE && init_resp_cnt == INIT_RESP_TIME_1) // 100 uS wait
      // NOTE: Edge case = what if di nagrespond?
      dsb18b20_response <= DS18B20_WIRE;
    else
      dsb18b20_response <= 1'b0;
  // Flag if Temperature has already been requested
  initial temp_conv_requested = 1'b0;
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      temp_conv_requested <= 1'b0;
    else if(state == TEMP_CONV_DONE)
      temp_conv_requested <= 1'b1;
    else if(state == READ_DONE)
      temp_conv_requested <= 1'b0;
    else
      temp_conv_requested <= temp_conv_requested;
      
  /* Writing */
  // Counter
  initial write_cnt = 11'b0;
  always@ (posedge CLK or negedge RST_N)
    if(!RST_N)
      write_cnt <= 11'b0;
    else if ((state == TEMP_CONV_REQUEST) || (state == READ_REQUEST))
      //NOTE: write_cnt >= 11'd1_674 ???
      write_cnt <= (write_cnt <= WRITE_TIME_TOTAL) ? write_cnt + 1'b1 : 11'b0;
    else
      write_cnt <= 11'b0;
  // Set Command
  initial command = 16'h0000;
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      command <= 16'h0000;
    else if (state == TEMP_CONV_REQUEST)
      command <= {CONVERT_TEMP, ROM_SKIP};
    else if (state == READ_REQUEST)
      command <= {READ_TEMP, ROM_SKIP};
    else
      command <= 16'h0000;
  // Write Bit Counter  
  initial write_bit_cnt = 5'b0;
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      write_bit_cnt <= 5'b0;
    // NOTE: can't it be write_bit_num <= 4'd15 para less lang yung register?
    else if ((state == TEMP_CONV_REQUEST) || (state == READ_REQUEST))
      if(write_bit_cnt < 5'd16)
        write_bit_cnt <= (write_cnt == WRITE_TIME_TOTAL) ? write_bit_cnt + 1'd1 : write_bit_cnt;
      else
        write_bit_cnt <= write_bit_cnt;
    else
      write_bit_cnt <= 5'd0;
  // Write Done
  initial write_done = 1'b0;
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      write_done <= 1'b0;
    // NOTE: can't it be write_bit_num == 4'd15 para less lang yung register?
    else if (((state == TEMP_CONV_REQUEST) || (state == READ_REQUEST)))
      write_done <= (write_bit_cnt == 5'd16) ? 1'b1 : 1'b0;
    else
      write_done <= 1'b0;
  // Write Data
  initial write_data = 1'b0;
  always @(posedge CLK or negedge RST_N)
    if (!RST_N)
      write_data <= 1'b0;
    else if (write_cnt <= WRITE_TIME_TRIG)
      write_data <= 1'b0;
    else if (write_cnt > WRITE_TIME_LOW && write_cnt < WRITE_TIME_HIGH)
      case(write_bit_cnt)
        5'd0:    write_data <= command[ 0];
        5'd1:    write_data <= command[ 1];
        5'd2:    write_data <= command[ 2];
        5'd3:    write_data <= command[ 3];
        5'd4:    write_data <= command[ 4];
        5'd5:    write_data <= command[ 5];
        5'd6:    write_data <= command[ 6];
        5'd7:    write_data <= command[ 7];
        5'd8:    write_data <= command[ 8];
        5'd9:    write_data <= command[ 9];
        5'd10:   write_data <= command[10];
        5'd11:   write_data <= command[11];
        5'd12:   write_data <= command[12];
        5'd13:   write_data <= command[13];
        5'd14:   write_data <= command[14];
        5'd15:   write_data <= command[15];
        default: write_data <= 1'b0;
      endcase
    else if (write_cnt >= WRITE_TIME_HIGH && write_cnt < WRITE_TIME_TOTAL)
      write_data <= 1'b1;
    else
     //NOTE: Might need to change;
      write_data <= write_data;
      
  /* Reading */
  // Counter
  initial read_cnt = 11'b0;
  always@ (posedge CLK or negedge RST_N)
    if(!RST_N)
      read_cnt <= 11'b0;
    else if ((state == READ_DATA))
      read_cnt <= (read_cnt > READ_TIME_TOTAL) ? 11'b0 : read_cnt + 1'b1;
    else
      read_cnt <= 11'b0;  
  // Read Bit Counter
  initial read_bit_cnt = 5'd0;
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      read_bit_cnt <= 5'd0;
    else if(state == READ_DATA)
      read_bit_cnt <= (read_cnt == READ_TIME_HIGH) ? read_bit_cnt + 1'b1 : read_bit_cnt;
    else
      read_bit_cnt <= 5'd0;      
  // Read Data
  initial read_data = 16'd0;
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      read_data <= 16'd0;
    else if(read_cnt == READ_TIME_TRIG && read_bit_cnt <= 5'd15)
      read_data <= {DS18B20_WIRE, read_data[15:1]};
    else
      read_data <= read_data;
  // Read Done
  initial read_done = 1'b0;
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      read_done <= 1'b0;
    else if(read_bit_cnt == 5'd16)
      read_done <= 1'b1;
    else
      read_done <= 1'b0;
  // Assign read data to output
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      TEMPERATURE <= 16'd0;
    else if (read_done)
      TEMPERATURE <= read_data;
    else
      TEMPERATURE <= TEMPERATURE;
      
  /* Output Controlling */
  initial ds18b20_wire = 1'b1;
  always @(posedge CLK or negedge RST_N)
    if(!RST_N)
      ds18b20_wire <= 1'b1;
    else if (init_req_cnt >= INIT_REQ_TIME_2 && init_req_cnt <= INIT_REQ_TIME)
      ds18b20_wire <= 1'b0;
    else if (init_resp_cnt >= INIT_RESP_TIME_3 && init_resp_cnt <= INIT_RESP_TIME_4)
      ds18b20_wire <= 1'bz;
    else if ((state == TEMP_CONV_REQUEST) || (state == READ_REQUEST))
      ds18b20_wire <= write_data;
    else if (state == READ_DATA && read_cnt <= READ_TIME_LOW)
      ds18b20_wire <= 1'b0;
    else if (state == READ_DATA && read_cnt > READ_TIME_LOW && read_cnt <= READ_TIME_HIGH)
      ds18b20_wire <= 1'bz;
    else
      ds18b20_wire <= 1'b1;

  assign DS18B20_WIRE = ds18b20_wire;
  
  /* State LED Debugging */
  /* initial STATE_LED = 9'd0;
  always @(state)
    case(state)
      PREPARE:             STATE_LED = 9'b0000_0000_1;
      INITIALIZE_REQUEST:  STATE_LED = 9'b0000_0001_0;
      INITIALIZE_RESPONSE: STATE_LED = 9'b0000_0010_0;
      TEMP_CONV_REQUEST:   STATE_LED = 9'b0000_0100_0;
      TEMP_CONV_WAIT:      STATE_LED = 9'b0000_1000_0;
      TEMP_CONV_DONE:      STATE_LED = 9'b0001_0000_0;
      READ_REQUEST:        STATE_LED = 9'b0010_0000_0;
      READ_DATA:           STATE_LED = 9'b0100_0000_0;
      READ_DONE:           STATE_LED = 9'b1000_0000_0;
    endcase */
endmodule