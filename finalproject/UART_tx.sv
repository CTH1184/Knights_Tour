module UART_tx(
    trmt,
    tx_data,
    clk,
    rst_n,
    TX,
    tx_done
);
    // define inputs
    input logic trmt; // asserted when transmission is initiated.
    input logic [7:0] tx_data; // the data being transmitted
    input logic clk, rst_n; // control signals

    // define outputs
    output logic TX; // the serial data outputted.
    output logic tx_done; // asserted when transmission is complete.

    // define internal signals
    logic init; // asserted if we are in the process of transmitting a byte.
    logic shift; // asserted if we are shifting out a byte.
    logic transmitting; // asserted if we are in the process of transmitting a byte.
    logic set_done; // asserted if we are done transmitting a byte.

    // state enumeration
    typedef enum logic[1:0]
    {
        IDLE,
        CLEAR_REGISTER,
        TRANSMIT,
        DONE
    } STATE;

    STATE curr_state;
    STATE nxt_state;

    //////////////////////
    /* shifter register */
    //////////////////////
    logic [8:0] tx_shift_reg_d;
    logic [8:0] tx_shift_reg;

    assign tx_shift_reg_d = init ? {tx_data,1'b0} :
                            shift ? {1'b1,tx_shift_reg[8:1]} : tx_shift_reg;

    // tx is the LSB of the register being shifted out.
    assign TX = tx_shift_reg[0];

    always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        tx_shift_reg <= '1;
    else
        tx_shift_reg <= tx_shift_reg_d;
    end

    //////////////////
    /* baud counter */
    //////////////////

    logic [11:0] baud_cnt;
    assign shift = (baud_cnt == 12'hA2C); // shift when the counter is full.

    always_ff @(posedge clk) begin
        case ({init|shift,transmitting}) inside
            2'b1?: baud_cnt <= '0;
            // TODO redundant logic here
            2'b01: baud_cnt <= (baud_cnt == 12'hA2C ? 12'h000 : baud_cnt + 1);
            2'b00: baud_cnt <= baud_cnt;
        endcase
    end

    /////////////////
    /* bit counter */
    /////////////////
    logic [3:0] bit_cnt; // how many bits were shifted

    always_ff @(posedge clk) begin
        case ({init,shift}) inside
            2'b1?: bit_cnt <= '0;
            2'b01: bit_cnt <= bit_cnt + 1;
            2'b00: bit_cnt <= bit_cnt;
        endcase
    end

    //////////////////
    /* tx_done flop */
    //////////////////
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            tx_done <= 1'b0;
        else if (init)
            tx_done <= 1'b0;
        else if (set_done)
            tx_done <= 1'b1;
    end

    /////////////////
    /* state logic */
    /////////////////

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            curr_state <= IDLE;
        else
            curr_state <= nxt_state;
    end

    always_comb begin
        // default assignments
        transmitting = 1'b0;
        init = 1'b0;
        set_done = 1'b0;
        nxt_state = curr_state;

        unique case (curr_state)
            IDLE: begin
                if (trmt) begin
                    init = 1'b1;
                    nxt_state = CLEAR_REGISTER;
                end
            end


            CLEAR_REGISTER: begin
                init = 1'b1;
                nxt_state = TRANSMIT;
            end


            TRANSMIT: begin
                transmitting = 1'b1;

                // if we have shifted 9 bits, we are done at the next state.
                if (bit_cnt[3] & bit_cnt[1]) begin
                    set_done = 1'b1;
                    nxt_state = IDLE;
                end
            end

            // how did we get here?
            default: nxt_state = IDLE;

        endcase
    end

endmodule