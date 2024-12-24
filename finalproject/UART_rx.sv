module UART_rx(
    output logic [7:0] rx_data, // the received data
    output logic rdy, // asserted when the value in rx_data is valid

    input logic RX, // the serial input from the transmitter
    input logic clr_rdy, // asserted to clear the ready signal.

    input logic clk,
    input logic rst_n
);


    // TODO need to double flop RX for metastability.
    logic RX_q_1;
    logic RX_q_2;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            RX_q_1 <= 1;
            RX_q_2 <= 1;
        end else begin
            RX_q_1 <= RX;
            RX_q_2 <= RX_q_1;
        end
    end

    // state enumeration
    typedef enum logic[1:0]
    {
        IDLE,
        RECEIVE
    } STATE;

    STATE curr_state;
    STATE nxt_state;
    logic start, shift, receiving, set_rdy; // SM control signals

    //////////////////////
    /* shifter register */
    //////////////////////
    logic [8:0] rx_shift_reg_d;
    logic [8:0] rx_shift_reg;

    assign rx_shift_reg_d = shift ? {RX_q_2, rx_shift_reg[8:1]} : rx_shift_reg;

    // rx_data is the bottom 8 bits of the register being shifted in.
    assign rx_data = rx_shift_reg[7:0];

    always_ff @(posedge clk) begin
        rx_shift_reg <= rx_shift_reg_d;
    end


    /////////////////
    /* bit counter */
    /////////////////
    logic [3:0] bit_cnt; // how many bits were shifted

    always_ff @(posedge clk) begin
        case ({start,shift}) inside
            2'b1?: bit_cnt <= '0;
            2'b01: bit_cnt <= bit_cnt + 1;
            2'b00: bit_cnt <= bit_cnt;
        endcase
    end

    //////////////////
    /* baud counter */
    //////////////////

    logic [11:0] baud_cnt;

    // shift when the counter is empty AND we are not on the start or stop bit.
    assign shift = ~|baud_cnt[11:0] && (|bit_cnt || ~(bit_cnt[3] & bit_cnt[1]));

    always_ff @(posedge clk) begin
        case ({start|shift,receiving}) inside
            2'b1?: baud_cnt <= receiving ? 12'hA2C: 12'h516;   // decides whether to divide counter by two
                                                                // in order to synchronize the rx on half
                                                                // baud cycles with the tx.
            2'b01: baud_cnt <= baud_cnt - 1;
            2'b00: baud_cnt <= baud_cnt;
        endcase
    end

    //////////////////
    /* rdy flop */
    //////////////////
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            rdy <= 1'b0;
        else if (start|clr_rdy)
            rdy <= 1'b0;
        else if (set_rdy)
            rdy <= 1'b1;
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

    always_comb begin: nxt_state_logic

        // default assignments
        start = 1'b0;
        receiving = 1'b0;
        set_rdy = 1'b0;
        nxt_state = curr_state;

        case (curr_state)
            IDLE:
                if (!RX_q_2) begin
                    start = 1'b1;
                    nxt_state = RECEIVE;
                end

            RECEIVE: begin
                // on the 10th bit, we are done receiving this byte.
                if (bit_cnt[3] & bit_cnt[1]) begin
                    receiving = 1'b0;
                    set_rdy = 1'b1;
                    nxt_state = IDLE;
                end else begin
                    receiving = 1'b1;
                end
            end
        endcase
    end

endmodule