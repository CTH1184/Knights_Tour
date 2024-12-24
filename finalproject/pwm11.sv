module pwm11(
    input logic clk,
    input logic rst_n,
    input logic [10:0] duty,
    output logic pwm_sig,
    output logic pwm_sig_n
);

    logic [10:0] cnt; // count ff signals
    logic q, d; // Output ff signals

    /* Count ff */
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            cnt <= 0;
        else
            cnt <= cnt + 1;
    
    assign d = (cnt < duty) ? 1'b1 : 1'b0;

    /* Output flip flop */
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n) begin
            pwm_sig <= 0;
            pwm_sig_n <= 1;
        end
        else begin
            pwm_sig <= d;
            pwm_sig_n <= ~d;
        end

endmodule