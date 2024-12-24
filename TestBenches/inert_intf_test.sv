module inert_intf_test(
    input logic clk,
    input logic RST_n,
    output logic SS_n,
    output logic SCLK,
    output logic MOSI,
    input logic MISO,
    input logic INT,
    output logic [7:0] LED
);

    logic rst_n; //reset signal

    logic sel; //SM select

    logic [7:0] heading; //8 bits to LED

    logic strt_cal; //start calibration
    logic cal_done; //calibration done

    //reset synchronizer instance
    reset_synch rs(.clk(clk), .RST_n(RST_n), .rst_n(rst_n));

    //inertial interface instance
    inert_intf ii(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO),
                  .INT(INT), .heading(heading), .strt_cal(strt_cal), .cal_done(cal_done),
                  .rdy(), .lftIR(1'b0), .rghtIR(1'b0), .moving(1'b1));

    //state machine
    typedef enum logic [1:0]
    {
        IDLE,
        CALIBRATE,
        DONE
    } state_t;
    state_t curr_state, next_state;

    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            curr_state <= IDLE;
        else
            curr_state <= next_state;
    end

    always_comb
    begin
        next_state = curr_state;
        sel = 0;
        strt_cal = 0;
        case (curr_state)
            IDLE:
                begin
                    next_state = CALIBRATE;
                    strt_cal = 1;
                end
            CALIBRATE:
                if (cal_done)
                begin
                    sel = 1;
                    next_state = DONE;
                end
            DONE: 
                begin
                    next_state = DONE;
                end
        endcase
    end

    //MUX
    assign LED = (sel) ? 8'hA5 : heading;


endmodule