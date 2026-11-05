module uart (
    input clk,
    input [7:0] send_data,
    input send_valid,
    output [7:0] received_data,
    output rx_ready,
    output tx_out,
    input rx_in,
    output tx_ready,    
    output rx_error_parity,
    output rx_error_frame
);

    uart_tx #(.countOfStrobe(468)) tx_unit (
        .clk(clk),
        .data(send_data),
        .data_rdy(send_valid),
        .tx(tx_out), 
        .transm_rdy(tx_ready)
    );

    uart_rx #(.countOfStrobe(468)) rx_unit (
        .clk(clk),
        .rx(rx_in),
        .data_out(received_data),
        .data_valid(rx_ready),
        .error_parity(rx_error_parity), 
        .error_frame(rx_error_frame)    
    );
endmodule