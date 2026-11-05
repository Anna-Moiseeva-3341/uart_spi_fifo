`timescale 1ns / 1ps

module spi #(
    parameter CLK_DIV = 8,
    parameter FIFO_DEPTH = 8
)(
    input clk,
    input rst_n,
    input wr_en,
    input [7:0] wr_data,
    input rd_en,
    output [7:0] rd_data,
    output empty,
    output sclk,
    output mosi,
    output cs,
    output busy,
    output tx_done,
    output rx_done,
    output fifo_full,
    output fifo_empty,
    output rx_overflow
);
    spi_master #(.CLK_DIV(CLK_DIV), .FIFO_DEPTH(FIFO_DEPTH)) u_master (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .full(fifo_full),
        .sclk(sclk),
        .mosi(mosi),
        .cs(cs),
        .busy(busy),
        .tx_done(tx_done),
        .fifo_empty(fifo_empty)
    );

    spi_slave #(.FIFO_DEPTH(FIFO_DEPTH)) u_slave (
        .clk(clk),
        .rst_n(rst_n),
        .sclk(sclk),
        .mosi(mosi),
        .cs(cs),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .empty(empty),
        .full(),
        .rx_done(rx_done),
        .overflow(rx_overflow)
    );
endmodule