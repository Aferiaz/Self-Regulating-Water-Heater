module WaterHeater (input  CLOCK_27A,
                    input  RST_N,
                    inout  DS_WIRE,
                    input  SCK,
                    input  MOSI,
                    input  SS,
                    output MISO,
                    output TRIGGER
                    );
  wire [15:0] temperature;
  wire [15:0] command;
  wire        unconnected;
  wire [13:0] setpoint;
  wire [13:0] proportional;
  wire [13:0] integral;
  wire [13:0] derivative;
  wire [24:0] time_value;
  wire [11:0] response;
  wire        pid_done;
  DS18B20_Master DS18B20  ( .CLK(CLOCK_27A),
                            .RST_N(RST_N),
                            .DS18B20_WIRE(DS_WIRE),
                            .TEMPERATURE(temperature)
                          );

  SPI_Remaster SPI  (.CLK(CLOCK_27A),
                     .RST_N(RST_N),
                     .SCK(SCK),
                     .MOSI(MOSI),
                     .SS(SS),
                     .MISO(MISO),
                     .WRITE_DATA(temperature),
                     .READ_DATA(command)
                    );

  /* SPI SPI (.CLK(SCK),
           .MOSI(MOSI),
           .MISO(MISO),
           .SC0(SS),
           .DATA_MOSI(unconnected),
           .DATA_MISO(16'hdead),
           .dflag(unconnected_2),
           .MISO(unconnected_3)
          ); */
  TimeProportion TimeProportion (.CLK(CLOCK_27A),
                                 .RST_N(RST_N),
                                 .VALUE(time_value),
                                 .TRIGGER(TRIGGER)
                                );
  Convert_Response Convert (.CLK(CLOCK_27A),
                            .RST_N(RST_N),
                            .EN(pid_done),
                            .PID_RESPONSE(response),
                            .TIME_VALUE(time_value)
                            );
  Command_Process Process (.CLK(CLOCK_27A),
                           .RST_N(RST_N), 
                           .COMMAND(command),
                           .SETPOINT(setpoint),
                           .PROPORTIONAL(proportional),
                           .INTEGRAL(integral),
                           .DERIVATIVE(derivative)
                          );
  PID PID (.CLK(CLOCK_27A),
					 .RSTN(RST_N),
           .kp({1'b0, proportional[13:3]}),
           .ki({1'b0, integral[13:3]}),
           .kd({1'b0, derivative[13:3]}),
           .measured_value(temperature[11:0]),
           .Setpoint({1'b0, setpoint[13:3]}),
           .response(response),
           .computed(pid_done)
          );
endmodule