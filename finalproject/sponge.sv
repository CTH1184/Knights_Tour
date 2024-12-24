module sponge(
    input logic clk, rst_n, go,
    output logic piezo, piezo_n
);
    // Internal parameters
    parameter FAST_SIM = 1;  // used to speed up simulation
	parameter CLK_FREQ = 50_000_000; // 50MHz clock frequency

	// Internal signals
    logic [14:0] f_count; // frequency counter
    logic [23:0] d_count; // duration timer

    // Duration clock done signals
    logic clk_23_done;
    logic clk_22_done;
    logic clk_both_done;
	logic clr_d_cnt;
	logic clk_done_rst;
	
	
	logic [14:0] note_per; //note period
	
	
    // State machine parameters for note sequence
    typedef enum logic[3:0] {
        INIT, NOTE_D7_1, NOTE_E7_1, NOTE_F7_1, NOTE_E7_2, NOTE_F7_2,
        NOTE_D7_2, NOTE_A6, NOTE_D7_3, DONE
    } state_t;
    state_t state, next_state;


	// Generate block to control duration increment
    logic [23:0] d_count_increment;
    generate if (FAST_SIM)
            assign d_count_increment = 24'h00_0010;  // Fast simulation: increment by 16
        else
            assign d_count_increment = 24'h00_0001;   // Normal mode: increment by 1
    endgenerate
	
	
	
    // Duration counters with adjustable increment based on FAST_SIM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_count <= 24'b0;
	end else if (clr_d_cnt) begin
		d_count <= 24'b0;
        end else if (go || (state != INIT && state != DONE)) begin
            d_count <= d_count + d_count_increment;
        end else if (state != next_state) begin
            d_count <= 24'b0;  // Reset when not playing a note
        end else 
	   d_count <= 24'b0;
    end

    // Frequency Count ff (for generating square wave)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            f_count <= 14'b0;
		end else if ((f_count == note_per) || (clr_d_cnt)) begin
			f_count <= 14'b0;
        end else begin
            f_count <= f_count + 1'b1;
        end
    end

  // Generate piezo signal based on note period divided by 2
  assign piezo = (f_count < (note_per >> 1)) ? 1'b0 : 1'b1;
  
    
    /* always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			piezo <= 1'b0;
		end else begin
			case (state)
                NOTE_D7_1, NOTE_D7_2, NOTE_D7_3: 
					piezo <= (f_count < (CLK_FREQ / 2 / 2349)); 
				NOTE_E7_1, NOTE_E7_2: 
					piezo <= (f_count < (CLK_FREQ / 2 / 2637));
				NOTE_F7_1, NOTE_F7_2: 
					piezo <= (f_count < (CLK_FREQ / 2 / 2794)); 
				NOTE_A6: 
					piezo <= (f_count < (CLK_FREQ / 2 / 1760));
				default: 
					piezo <= 1'b0; 
			endcase
        end
    end */
	
	assign piezo_n = ~piezo;
	

    // Assign duration completion signals based on d_count
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_23_done <= 1'b0;
            clk_22_done <= 1'b0;
            clk_both_done <= 1'b0;
        end else if (clk_done_rst) begin
			clk_23_done <= 1'b0;
			clk_22_done <= 1'b0;
            clk_both_done <= 1'b0;
		end else begin
            clk_23_done <= d_count[23];
            clk_22_done <= d_count[22];
            clk_both_done <= d_count[22] & d_count[23];
        end
    end

    // State machine to control note sequence
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= INIT;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state;
		clk_done_rst = 1'b0;
		clr_d_cnt = 1'b0;
	    note_per = 15'hxxxx;

        case (state)
            INIT: begin
				  if (go) begin
				    next_state = NOTE_D7_1;
				    clk_done_rst = 1'b1;
				    clr_d_cnt = 1'b1;
              end
				clr_d_cnt = 1'b1;
				end
            NOTE_D7_1: if (clk_23_done) begin
				next_state = NOTE_E7_1;
				clk_done_rst = 1'b1;
				clr_d_cnt = 1'b1;
			end else note_per = (CLK_FREQ / 2349);
            NOTE_E7_1: if (clk_23_done) begin
				next_state = NOTE_F7_1;
				clk_done_rst = 1'b1;
				clr_d_cnt = 1'b1;
			end else note_per = (CLK_FREQ / 2637);
            NOTE_F7_1: if (clk_23_done) begin
				next_state = NOTE_E7_2;
				clk_done_rst = 1'b1;
				clr_d_cnt = 1'b1;
			end else note_per = (CLK_FREQ / 2794);
            NOTE_E7_2: if (clk_both_done) begin
				next_state = NOTE_F7_2;
				clk_done_rst = 1'b1;
				clr_d_cnt = 1'b1;
			end else note_per = (CLK_FREQ / 2637);
            NOTE_F7_2: if (clk_22_done) begin
				next_state = NOTE_D7_2;
				clk_done_rst = 1'b1;
				clr_d_cnt = 1'b1;
			end else note_per = (CLK_FREQ / 2794);
            NOTE_D7_2: if (clk_both_done) begin
				next_state = NOTE_A6;
				clk_done_rst = 1'b1;
				clr_d_cnt = 1'b1;
			end else note_per = (CLK_FREQ / 2349);
            NOTE_A6: if (clk_22_done) begin
				next_state = NOTE_D7_3;
				clk_done_rst = 1'b1;
				clr_d_cnt = 1'b1;
			end else note_per = (CLK_FREQ / 1760);
            NOTE_D7_3: if (clk_23_done) begin
				next_state = INIT;
				clk_done_rst = 1'b1;
				clr_d_cnt = 1'b1;
			end else note_per = (CLK_FREQ / 2349);
        endcase
    end
  
	
	
	// Reset duration counter at the beginning of each note
    //always_ff @(posedge clk or negedge rst_n) begin
      //  if (!rst_n) begin
        //    d_count <= 24'b0;
     //   end else if (state != next_state) begin
      //      d_count <= 24'b0;
       // end
	//end
 
	
	
endmodule