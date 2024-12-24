module PID(
	input clk, rst_n,
	input moving, err_vld,
	input [11:0] error,
	input [9:0] frwrd,
	output [10:0] lft_spd,
	output [10:0] rght_spd
	);



	//P TERM
	logic signed [13:0] P_term;

	// Constant for P coefficient
    localparam P_COEFF = 6'h10; //16

    // Intermediate signal for saturated error
    logic signed [9:0] err_sat;
	logic [11:0] error_flopped;
	
    // Flop error sat to prevent timing issues
    always_ff @(posedge clk, negedge rst_n)
	    if (!rst_n)
		    error_flopped <= 0;
	    else
		    error_flopped <= error;

    // Saturate the error to 10 bits
    assign err_sat = (error_flopped[11] == 1'b1 && ~(&error_flopped[10:9])) ? -10'sh200 : // Negative saturation
                     (error_flopped[11] == 1'b0 && |error_flopped[10:9])  ?  10'sh1FF : error_flopped[9:0];  // Positive saturation
                           
    // Calculate the P term with saturation
    assign P_term = err_sat * $signed(P_COEFF);

	//I TERM
	logic signed [8:0] I_term;
	logic [14:0] integrator, nxt_integrator;
    logic ov; // Overflow flag


	//Intermediate values and control signals for nxt_integrator
	logic [14:0] int_sum;
	logic int_ctrl;
	logic [14:0] inter;


	//sign extend err_sat to 15 bits
    logic [14:0] sign_extend;
    assign sign_extend = { {5{err_sat[9]}}, err_sat};


    // Accumulator register with asynchronous reset
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            integrator <= 15'h0000;
        end else begin
            integrator <= nxt_integrator;
        end
    end

	//Intermediate sum of sign extend and integrator
	assign int_sum = integrator + sign_extend;

	// Overflow detection
	assign ov = ((integrator[14] == sign_extend[14]) && (int_sum[14] != integrator[14]));

	//Control signal for deciding between int_sum and integrator
	assign int_ctrl = (~ov & err_vld);

	assign inter = (int_ctrl) ? int_sum : integrator;

    // Next integrator value calculation
	assign nxt_integrator = (moving) ? inter : 15'h0000;


    // I_term output
    assign I_term = integrator[14:6];





	//D TERM
    localparam D_COEFF = 5'h07;

    // Internal signals
	logic signed [12:0] D_term;
    logic [9:0] err_reg1, err_reg2, prev_err;
	logic signed [9:0] D_diff;
    logic signed [7:0] D_diff_sat;

    // Register chain for delayed error values
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            err_reg1 <= 10'b0;
            err_reg2 <= 10'b0;
			prev_err <= 10'b0;
        end else if (err_vld) begin
            err_reg1 <= err_sat;
            err_reg2 <= err_reg1;
			prev_err <= err_reg2;
        end
    end

    // Subtraction to find D_diff
    assign D_diff = err_sat - prev_err;

    // Saturation to 8 bits using dataflow
    assign D_diff_sat = (D_diff > 8'sh7F)  ? 8'sh7F  :
                        (D_diff < 8'sh80) ? 8'sh80 : D_diff[7:0];

    // Signed multiplication
    assign D_term = (D_diff_sat) * $signed(D_COEFF);




	//PID Implementation
	logic [13:0] PID;
	logic [12:0] P_div2;
	logic [10:0] frwrd_0_extend;

	// Intermediate signals for saturation
	logic [10:0] lft_spd_int, rght_spd_int;

	//Divide p_term by 2
	assign P_div2 = (P_term >> 1);


	//zero-extended frwrd
	assign frwrd_0_extend = ({{1{1'b0}}, frwrd});

	//P, I, and D term sign extension and summation
	// Pipelined to prevent hold time issues.
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			PID <= 0;
		else
			PID = $signed({{1{P_div2[12]}},P_div2}) + $signed({{5{I_term[8]}}, I_term}) + $signed({{1{D_term[12]}}, D_term});


	// Intermediate left and right summations based on moving flag
	assign lft_spd_int = moving ? ($signed(PID[13:3]) + $signed(frwrd_0_extend)) : 11'h000;

	assign rght_spd_int = moving ? ($signed(frwrd_0_extend) - $signed(PID[13:3])) : 11'h000;



	// Saturate the output for lft_spd
	assign lft_spd = (~PID[13] & lft_spd_int[10]) ? 11'sh3FF : lft_spd_int[10:0];

	// Saturate the output for rght_spd
	assign rght_spd = (PID[13] & rght_spd_int[10]) ? 11'sh3FF : rght_spd_int[10:0];

endmodule