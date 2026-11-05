module uart_rx #(
    parameter countOfStrobe = 468
)(
    input clk,
    input rx,
    output reg [7:0] data_out = 0,
    output reg data_valid = 0,
    output reg error_parity = 0,
    output reg error_frame = 0
);
    reg [2:0] state = 3'd0;
    reg [15:0] cntStrobe = 0;
    reg [2:0] cntBit = 0;
    reg [7:0] shiftData = 0;
    reg rx_parity_bit = 0;

    reg rx_meta = 1;
    reg rx_sync = 1;
    always @(posedge clk) begin
        rx_meta <= rx;
        rx_sync <= rx_meta;
    end

    always @(posedge clk)
    begin
        data_valid <= 0;
        error_parity <= 0;
        error_frame <= 0;

        case(state)
            3'd0: begin
                cntStrobe <= 0;
                if (rx_sync == 0)
                    state <= 3'd1;
            end

            3'd1: begin
                if (cntStrobe < countOfStrobe / 2 - 1) begin
                    cntStrobe <= cntStrobe + 1;
                end else begin
                    cntStrobe <= 0;
                    if (rx_sync == 0) begin
                        cntBit <= 0;
                        state <= 3'd2;
                    end else begin
                        state <= 3'd0;
                    end
                end
            end

            3'd2: begin
                if (cntStrobe < countOfStrobe - 1) begin
                    cntStrobe <= cntStrobe + 1;
                end else begin
                    cntStrobe <= 0;
                    shiftData <= {rx_sync, shiftData[7:1]};
                    cntBit <= cntBit + 1;
                    if (cntBit == 3'd7)
                        state <= 3'd3;
                end
            end

            3'd3: begin
                if (cntStrobe < countOfStrobe - 1) begin
                    cntStrobe <= cntStrobe + 1;
                end else begin
                    cntStrobe <= 0;
                    rx_parity_bit <= rx_sync;
                    state <= 3'd4;
                end
            end

            3'd4: begin
                if (cntStrobe < countOfStrobe - 1) begin
                    cntStrobe <= cntStrobe + 1;
                end else begin
                    cntStrobe <= 0;
                    state <= 3'd0;
                    if (rx_sync != 1) begin
                        error_frame <= 1;
                    end else begin
                        data_out <= shiftData;
                        data_valid <= 1;
                        error_parity <= ((^shiftData) != rx_parity_bit);
                    end
                end
            end

            default: state <= 3'd0;
        endcase
    end
endmodule