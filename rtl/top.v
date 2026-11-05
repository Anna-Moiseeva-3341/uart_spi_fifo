`timescale 1ns / 1ps

module top #(
    parameter DEBOUNCE_COUNT = 500000 
)(
    input clk,
    input key_pressed,
    output o_LED1,
    output [3:0] debug_signal // 42, 43, 44, 46
);
    reg [3:0] rst_cnt = 0;
    reg sys_rst_n = 0;
    always @(posedge clk) begin
        if (rst_cnt < 4'hF) begin
            rst_cnt <= rst_cnt + 1;
            sys_rst_n <= 0;
        end else begin
            sys_rst_n <= 1;
        end
    end
    wire rst_n = sys_rst_n;

    reg [19:0] debounce_counter = 0;
    reg button_sync1 = 1, button_sync2 = 1, button_prev = 1;
    reg button_pressed_detected = 0;
    
    always @(posedge clk) begin
        button_sync1 <= key_pressed;
        button_sync2 <= button_sync1;
        if (button_sync2 != button_prev) debounce_counter <= DEBOUNCE_COUNT;
        else if (debounce_counter > 0) debounce_counter <= debounce_counter - 1;
        if (debounce_counter == 1) button_pressed_detected <= (button_sync2 == 0);
        else button_pressed_detected <= 0;
        button_prev <= button_sync2;
    end

    reg mode_select = 0; 
    reg [23:0] timer = 0; 
    reg tx_valid_pulse = 0; 
    reg [7:0] data_to_send = 8'h00; 

    always @(posedge clk) begin
        if (!rst_n) begin
             timer <= 0;
             data_to_send <= 0;
             mode_select <= 0;
        end else begin
            if (button_pressed_detected) mode_select <= ~mode_select;
            
            timer <= timer + 1;
            if (timer == 500) begin
                tx_valid_pulse <= 1;        
            end else if (timer == 505) begin
                tx_valid_pulse <= 0;        
            end else if (timer == 2700000) begin
                timer <= 0;
                data_to_send <= data_to_send + 1; 
            end
        end
    end

    assign o_LED1 = ~mode_select;
    wire uart_tx_wire;
    wire uart_tx_ready;    
    wire [7:0] uart_rx_data;
    wire uart_rx_ready;
    wire uart_err_parity;
    wire uart_err_frame;

    uart u_uart (
        .clk(clk),
        .send_data(data_to_send),
        .send_valid(tx_valid_pulse & ~mode_select),         
        .received_data(uart_rx_data),
        .rx_ready(uart_rx_ready),
        .rx_error_parity(uart_err_parity),
        .rx_error_frame(uart_err_frame),        
        .tx_out(uart_tx_wire), 
        .rx_in(uart_tx_wire), 
        .tx_ready(uart_tx_ready) 
    );

    reg data_match = 0;
    
    always @(posedge clk) begin
        if (uart_rx_ready) begin
            if (uart_rx_data == data_to_send)
                data_match <= 1;
            else
                data_match <= 0;
        end
    end

    wire spi_sclk;
    wire spi_mosi;
    wire spi_cs;
    wire spi_rx_done_wire;
    wire spi_rx_empty;

    spi u_spi (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(tx_valid_pulse & mode_select), 
        .wr_data(data_to_send),
        .rd_en(~spi_rx_empty),
        .rd_data(),
        .empty(spi_rx_empty),
        .sclk(spi_sclk),
        .mosi(spi_mosi),
        .cs(spi_cs),
        .busy(),
        .tx_done(),
        .rx_done(spi_rx_done_wire),
        .fifo_full(),
        .fifo_empty(),
        .rx_overflow()
    );

    assign debug_signal[0] = mode_select ? spi_rx_done_wire : data_match;
    assign debug_signal[1] = mode_select ? spi_sclk : uart_tx_wire;
    assign debug_signal[2] = mode_select ? spi_mosi : uart_rx_ready;
    assign debug_signal[3] = mode_select ? spi_cs : (uart_err_parity | uart_err_frame);
endmodule