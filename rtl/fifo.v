// fifo.v
`timescale 1ns / 1ps

module fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 8
)(
    input clk,
    input rst_n,
    input wr_en,
    input [DATA_WIDTH-1:0] wr_data,
    output full,
    input rd_en,
    output [DATA_WIDTH-1:0] rd_data,
    output empty
);
    localparam AW = $clog2(FIFO_DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    reg [AW-1:0] wr_ptr;
    reg [AW-1:0] rd_ptr;
    reg [AW:0] count;

    wire do_wr = wr_en && !full;
    wire do_rd = rd_en && !empty;

    assign full = (count == FIFO_DEPTH);
    assign empty = (count == 0);
    assign rd_data = mem[rd_ptr];

    always @(posedge clk) begin
        if (do_wr) begin
            mem[wr_ptr] <= wr_data;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            if (do_wr) wr_ptr <= wr_ptr + 1'b1;
            if (do_rd) rd_ptr <= rd_ptr + 1'b1;
            if (do_wr && !do_rd)
                count <= count + 1'b1;
            else if (!do_wr && do_rd)
                count <= count - 1'b1;
        end
    end
endmodule