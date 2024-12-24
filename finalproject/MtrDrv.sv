module MtrDrv(
    input logic clk,            // system clock
    input logic rst_n,          // async active low reset
    input signed [10:0] lft_spd,       // signed left motor speed
    input signed [10:0] rght_spd,      // signed right motor speed
    output lftPWM1,             // to power mosfets that drive left motor
    output lftPWM2,
    output rghtPWM1,            // to power mosfets that drive right motor
    output rghtPWM2
);

    /* Scale left speed and right speed so val of 0 goes to 50% duty cycle */
    logic [10:0] scaled_lft_spd;
    logic [10:0] scaled_rght_spd;

    assign scaled_lft_spd = lft_spd + 11'h400;
    assign scaled_rght_spd = rght_spd + 11'h400;

    /* Instantiate pwm11 modules to provide motor drive output values */
    pwm11 leftPWM(
        .clk(clk),
        .rst_n(rst_n),
        .duty(scaled_lft_spd),
        .pwm_sig(lftPWM1),
        .pwm_sig_n(lftPWM2)
    );

    pwm11 rightPWM(
        .clk(clk),
        .rst_n(rst_n),
        .duty(scaled_rght_spd),
        .pwm_sig(rghtPWM1),
        .pwm_sig_n(rghtPWM2)
    );

endmodule