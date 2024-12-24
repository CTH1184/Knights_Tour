`default_nettype none
module RemoteComm(
    output logic cmd_sent,
    output logic TX,
    output logic resp_rdy,
    output logic [7:0] resp,
    input wire logic RX,
    input wire logic [15:0] cmd,
    input wire logic send_cmd,
    input wire logic clk,
    input wire logic rst_n
);

// define internal signals
logic tx_done;
logic trmt;
logic [7:0] tx_data;
logic sel;
logic set_cmd_sent;

// instantiate UART
UART uart_0(.clk(clk),.rst_n(rst_n),.RX(RX),.TX(TX),.rx_rdy(resp_rdy),.clr_rx_rdy(),.rx_data(resp),.trmt(trmt),.tx_data(tx_data),.tx_done(tx_done));

// low byte of cmd flop
logic [7:0] low_cmd_q;

// mux for the high or low byte of cmd.
assign tx_data = (sel) ? cmd[15:8] : low_cmd_q;

always_ff @(posedge clk) begin
    if (send_cmd)
        low_cmd_q <= cmd[7:0];
end

// ff for cmd_sent
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        cmd_sent <= 1'b0;
    else if (send_cmd)
        cmd_sent <= 1'b0;
    else if (set_cmd_sent)
        cmd_sent <= 1'b1;
end

typedef enum logic [1:0] {
    IDLE,
    SEND_HIGH_BYTE,
    WAIT_FOR_HIGH_ACK,
    SEND_LOW_BYTE
} state_t;

state_t state;
state_t next_state;

always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

always_comb begin: nxt_state_logic
    // default assignments
    next_state = state;
    set_cmd_sent = 0;
    trmt = 0;
    sel = 0;

    case (state)

        IDLE: begin
            if (send_cmd) begin
                sel = 1;
                trmt = 1;
                next_state = SEND_HIGH_BYTE;
            end
        end


        SEND_HIGH_BYTE: begin
            sel = 1;

            if (tx_done) begin
                next_state = WAIT_FOR_HIGH_ACK;
            end
        end

        WAIT_FOR_HIGH_ACK: begin
            trmt = 1;

            if (!tx_done) begin
                next_state = SEND_LOW_BYTE;
            end
        end

        SEND_LOW_BYTE: begin
            if (tx_done) begin
                set_cmd_sent = 1;
                next_state = IDLE;
            end
        end

        // cosmic bitflip
        // default: next_state = IDLE;
    endcase

end



endmodule
`default_nettype wire