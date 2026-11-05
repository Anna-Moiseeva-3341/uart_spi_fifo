`timescale 1ns / 1ps

module spi_master #(
    parameter CLK_DIV = 8,
    parameter FIFO_DEPTH = 8
)(
    input clk,
    input rst_n,
    input wr_en,
    input [7:0] wr_data,
    output full,
    output reg sclk = 0,
    output reg mosi = 0,
    output reg cs = 1,
    output reg busy = 0,
    output reg tx_done = 0,
    output fifo_empty
);
    wire [7:0] rd_data;
    reg rd_en;
    wire empty;

    fifo #(.DATA_WIDTH(8), .FIFO_DEPTH(FIFO_DEPTH)) tx_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .full(full),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .empty(empty)
    );

    assign fifo_empty = empty;

    reg [CLK_DIV-1:0] clk_div_counter;
    
    localparam STATE_IDLE  = 0;
    localparam STATE_FETCH = 1;
    localparam STATE_TX    = 2;
    localparam STATE_FINISH = 3;
    
    reg [1:0] state; 
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk <= 0;
            mosi <= 0;
            cs <= 1;
            busy <= 0;
            tx_done <= 0;
            state <= STATE_IDLE;
            bit_cnt <= 0;
            shift_reg <= 0;
            clk_div_counter <= 0;
            rd_en <= 0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    tx_done <= 0;
                    if (!empty) begin
                        busy <= 1;
                        rd_en <= 1;        
                        state <= STATE_FETCH;
                    end else begin
                        busy <= 0;
                        rd_en <= 0;
                        cs <= 1;
                    end
                end

                STATE_FETCH: begin
                    rd_en <= 0; 
                    shift_reg <= rd_data; 
                    bit_cnt <= 0;
                    clk_div_counter <= 0;
                    
                    cs <= 0;      
                    sclk <= 0;   
                    
                    mosi <= rd_data[7]; 
                    shift_reg <= {rd_data[6:0], 1'b0};
                    
                    state <= STATE_TX;
                end

                STATE_TX: begin
                    if (clk_div_counter < CLK_DIV - 1) begin
                        clk_div_counter <= clk_div_counter + 1;
                    end else begin
                        clk_div_counter <= 0;
                        sclk <= ~sclk;

                        if (sclk == 0) begin 
                        end else begin 
                            bit_cnt <= bit_cnt + 1;
                            if (bit_cnt < 7) begin
                                mosi <= shift_reg[7];
                                shift_reg <= {shift_reg[6:0], 1'b0};
                            end else begin
                                state <= STATE_FINISH;
                            end
                        end
                    end
                end
                
                STATE_FINISH: begin
                     if (clk_div_counter < CLK_DIV - 1) begin
                        clk_div_counter <= clk_div_counter + 1;
                     end else begin
                        sclk <= 0; 
                        cs <= 1;   
                        mosi <= 0;
                        tx_done <= 1; 
                        state <= STATE_IDLE;
                     end
                end
            endcase
        end
    end
endmodule