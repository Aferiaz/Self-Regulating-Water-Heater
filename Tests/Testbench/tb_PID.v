module tb_PID #(parameter WIDTH = 12, MaxRange = 11'b0111111_0000, MinRange = 11'b0000000_0000);
reg CLK;
reg signed [WIDTH-1:0] kp, ki, kd;
reg [WIDTH-1:0] measured_value;
reg [WIDTH-1:0] Setpoint;
wire signed[WIDTH-1:0] response;
wire computed; // flag for saying that the response is now valid

initial
begin
	CLK = 0;
	kp = 0;
	ki = 0;
	kd = 0;
	measured_value = 0;
	Setpoint = 0;
end


PID #(.WIDTH(WIDTH), 
	.MaxRange(MaxRange), 
	.MinRange(MinRange))
UUT	(
	.kp(kp), 
	.ki(ki), 
	.kd(kd), 
	.measured_value(measured_value), 
	.Setpoint(Setpoint), 
	.CLK(CLK), 
	.response(response), 
	.computed(computed)
);

always #10 CLK <= ~CLK;

initial
begin
    #10 CLK = 0;
	#35 Setpoint = 12'b00100100_0000;
	#10 measured_value = 12'b00011000_0010; // 24.125
	#10 kp = 12'b00000000_1000; //0.5
	#100 measured_value = 12'b00011100_0010; //28.125
	#100 measured_value = 12'b00100000_0010; //32.3215
	#100 measured_value = 12'b00100010_1000; //34.5
	#100 measured_value = 12'b00100100_0000; //36
	#100 measured_value = 12'b00011000_0010; // 24.125
	#10 kp = 12'b00000000_0000;
	kd = 12'b00000000_1000; //0.5
	#100 measured_value = 12'b00011100_0010; //28.125
	#100 measured_value = 12'b00100000_0010; //32.3215
	#100 measured_value = 12'b00100010_1000; //34.5
	#100 measured_value = 12'b00100100_0000; //36
	#100 measured_value = 12'b00011000_0010; // 24.125
	#10 kd = 12'b00000000_0000;
	//integral doesn't help our system because setpoint is minimum
	ki = 12'b00000000_1000; //0.5
	#100 measured_value = 12'b00011100_0010; //28.125
	#100 measured_value = 12'b00100000_0010; //32.3215
	#100 measured_value = 12'b00100010_1000; //34.5
	#100 measured_value = 12'b00100100_0000; //36
	#500
	$stop;
end
endmodule