module UART_wrapper(
    output logic TX,
    output logic cmd_rdy,
    output logic [15:0] cmd,
    output logic tx_done,

    input logic RX,
    input logic clr_cmd_rdy,
    input logic trmt,
    input logic [7:0] resp,

    input logic clk,
    input logic rst_n
);

typedef enum logic [1:0] {
    IDLE,
    RECEIVING_CMD_HIGH,
    RECEIVING_CMD_LOW
} state;

// state variables
state current_state;
state next_state;

/****** intermediate logic ******/

// asserted by SM when the first byte of the command is received.
logic switch_new_cmd;

// one byte output of received data from UART.
logic [7:0] rx_data;

// input to the flip flop storing the high bits of cmd
logic [7:0] high_bits_of_cmd_d;

// asserted when we acknowledge a received transmission from UART
logic clr_rx_rdy;

// sets the SR flop storing cmd_rdy
logic set_cmd_rdy;

// asserted when we are changing cmd
logic storing;


/* instantiate UART */
UART uart_0(
    .clk(clk),
    .rst_n(rst_n),
    .RX(RX),
    .TX(TX),
    .rx_rdy(rx_rdy),
    .clr_rx_rdy(clr_rx_rdy),
    .rx_data(rx_data),
    .trmt(trmt),
    .tx_data(resp),
    .tx_done(tx_done)
);


// TODO can we combine this with following FF?
assign high_bits_of_cmd_d = switch_new_cmd ? rx_data : cmd[15:8];

always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        cmd[15:8] <= '0;
    else
        cmd[15:8] <= high_bits_of_cmd_d;
end

assign cmd[7:0] = rx_data;


// SR flop for cmd_rdy
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        cmd_rdy <= 0;
    else if (storing | clr_cmd_rdy)
        cmd_rdy <= 0;
    else if (set_cmd_rdy)
        cmd_rdy <= 1;
end

/**
 * State Machine logic
 */
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always_comb begin : nxt_state_logic
    // default assignments
    set_cmd_rdy = 0;
    storing = 0;
    clr_rx_rdy = 0;
    switch_new_cmd = 0;
    next_state = current_state;

    case (current_state)
        IDLE: begin
            if (!RX) begin
                storing = 1;
                next_state = RECEIVING_CMD_HIGH;
            end
        end

        RECEIVING_CMD_HIGH: begin
            storing = 1;
            switch_new_cmd = 1;

            if (rx_rdy) begin
                clr_rx_rdy = 1;
                next_state = RECEIVING_CMD_LOW;
            end
        end

        RECEIVING_CMD_LOW: begin
            if (rx_rdy) begin
                clr_rx_rdy = 1;
                set_cmd_rdy = 1;
                next_state = IDLE;
            end
        end
    endcase
end


endmodule