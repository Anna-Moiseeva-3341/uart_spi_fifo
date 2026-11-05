`timescale 1ns / 1ps

module spi_slave #(
    parameter FIFO_DEPTH = 8
)(
    input clk,
    input rst_n,
    input sclk,
    input mosi,
    input cs,
    input rd_en,
    output [7:0] rd_data,
    output empty,
    output full,
    output reg rx_done,
    output reg overflow
);
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    reg prev_sclk;
    reg wr_en;
    reg [7:0] wr_data;

    wire sclk_rise = (prev_sclk == 1'b0) && (sclk == 1'b1);

    fifo #(.DATA_WIDTH(8), .FIFO_DEPTH(FIFO_DEPTH)) rx_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .full(full),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .empty(empty)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
            bit_cnt <= 0;
            prev_sclk <= 0;
            wr_en <= 0;
            wr_data <= 0;
            rx_done <= 0;
            overflow <= 0;
        end else begin
            prev_sclk <= sclk;
            wr_en <= 1'b0;
            rx_done <= 1'b0;

            if (cs) begin
                bit_cnt <= 0;
            end else if (sclk_rise) begin
                shift_reg <= {shift_reg[6:0], mosi};
                bit_cnt <= bit_cnt + 1'b1;
                if (bit_cnt == 3'd7) begin
                    if (full) begin
                        overflow <= 1'b1;
                    end else begin
                        wr_en <= 1'b1;
                        wr_data <= {shift_reg[6:0], mosi};
                        rx_done <= 1'b1;
                    end
                end
            end
        end
    end
endmodule