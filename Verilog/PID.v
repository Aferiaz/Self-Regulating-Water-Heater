// PID module
// response 12'bxxxxxxxxxxxx
// response[11] = sign bit
// response[10:4] = whole num
// response[3:0] = decimal nums
module PID #(parameter WIDTH = 12, MaxRange = 11'b0111111_0000, MinRange = 11'b0000000_0000)(kp, ki, kd, measured_value, Setpoint, CLK, response, computed);
input CLK;
input signed [WIDTH-1:0] kp, ki, kd;
input [WIDTH-1:0] measured_value;
input [WIDTH-1:0] Setpoint;
output reg signed[WIDTH-1:0] response;
reg signed[(WIDTH*2)-1:0] iresponse_hold, presponse_hold, dresponse_hold;
reg signed[WIDTH-1:0] presponse, iresponse, dresponse; // holders for the responses of each portion
reg signed[WIDTH-1:0] e; // error signal
reg signed[WIDTH-1:0] lastInput; // derivation of dresponse
reg pflag, iflag, dflag, sflag; // flags for stating that all portions are ready for summing; sflag is for start computing
reg piflag, iiflag, diflag, siflag; // internal flags
output reg computed; // flag for saying that the response is now valid

initial
begin
	lastInput = 0;
	e = 0;
	dresponse = 0;
	iresponse = 0;
	sflag = 0;
	piflag = 0;
	iiflag = 0;
	diflag = 0;
end

// Total = 5 CLK CYCLES
always @ (posedge CLK)
begin
	// 1 CLK CYCLE
	if(sflag == 0)
	begin
		sflag <= 1;
		pflag <= 0;
		iflag <= 0;
		dflag <= 0;
		computed <= 0;
		if(Setpoint < measured_value) // Since our MinRange is the Setpoint, we  cannot have negative error
			e <= 0;
		else
			e <= Setpoint - measured_value; // registers the error value
	end
	
	// 2 CLK CYCLES
	else if(pflag == 1 & iflag == 1 & dflag == 1) // adds all responses
	begin
		if(siflag == 1) // to prevent output from going out of range
		begin
			sflag <= 0;
			siflag <= 0;
			computed <= 1;
			if(response >= MaxRange)
				response <= MaxRange;
			else if(response <= MinRange)
				response <= MinRange;
			else
				response <= response;
		end
		else // computes initial value of proportional response
		begin
			response <= presponse + iresponse + dresponse;
			siflag <= 1;
		end
	end	
	
	// 2 CLK CYCLES
	else
	begin
		// 2 CLK CYCLES
		if(pflag == 0) // P portion
		begin
			if(piflag == 1) // to prevent output from going out of range
			begin
				pflag <= 1;
				piflag <= 0;
				if(presponse_hold[15:8] >= MaxRange)
					presponse <= MaxRange;
				else if(presponse_hold[15:8] <= MinRange)
					presponse <= MinRange;
				else
					presponse <= presponse_hold[15:4];
			end
			else // computes initial value of proportional response
			begin
				presponse_hold <= kp*e;
				piflag <= 1;
			end
		end
		else
			presponse <= presponse;
		
		// 2 CLK CYCLES
		if(iflag == 0) // I portion
		begin
			if(iiflag == 1) // to prevent output from going out of range
			begin
				iflag <= 1;
				iiflag <= 0;
				if(iresponse_hold[15:8] >= MaxRange)
					iresponse <= MaxRange;
				else if(iresponse_hold[15:8] <= MinRange)
					iresponse <= MinRange;
				else
					iresponse <= iresponse_hold[15:4];
			end
			else // computes initial value of integral response
			begin
				iresponse_hold <= (iresponse << 4) + (ki*e);
				iiflag <= 1;
			end
		end
		else
			iresponse <= iresponse;
			
		// 2 CLK CYCLES
		if(dflag == 0) // D portion
		begin
			if(diflag == 1) // to prevent output from going out of range
			begin
				lastInput <= measured_value;
				dflag <= 1;
				diflag <= 0;
				if(dresponse_hold[15:8] >= MaxRange)
					dresponse <= MaxRange;
				else if(dresponse_hold[15:8] <= MinRange)
					dresponse <= MinRange;
				else
					dresponse <= dresponse_hold[15:4];
			end
			else // computes initial value of differential response
			begin
				dresponse_hold <= kd*(measured_value - lastInput);
				diflag <= 1;
			end
		end
		else
			dresponse <= dresponse;
	end
end
endmodule