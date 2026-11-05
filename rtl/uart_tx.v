module uart_tx #( 
    parameter countOfStrobe = 468
)( 
    input clk, 
    input [7:0] data, 
    input data_rdy, 
    output reg tx = 1, 
    output reg transm_rdy = 1 
); 
    reg [1:0] state = 2'b00;
    reg [15:0] cntStrobe = 0;
    reg [4:0] cntBit = 0; 
    reg [7:0] shiftData; 
    reg parity_bit;

    always @(posedge clk)
    begin 
        case(state)
            2'b00 : begin 
                if (data_rdy) begin 
                    state <= 2'b01; 
                    shiftData <= data;
                    parity_bit <= ^data; 
                    transm_rdy <= 0;        
                    tx <= 0;
                end 
            end 
            
            2'b01 : begin 
                if (cntStrobe < countOfStrobe - 1) begin
                    cntStrobe <= cntStrobe + 1; 
                end else begin 
                    cntStrobe <= 0; 
                    
                    if (cntBit == 0) begin 
                        cntBit <= 1; 
                        tx <= shiftData[0]; 
                        shiftData[6:0] <= shiftData[7:1]; 
                    end 
                    else if (cntBit > 0 && cntBit < 8) begin
                        cntBit <= cntBit + 1; 
                        tx <= shiftData[0]; 
                        shiftData[6:0] <= shiftData[7:1]; 
                    end
                    else if (cntBit == 8) begin
                        cntBit <= 9;
                        tx <= parity_bit;
                    end
                    else if (cntBit == 9) begin
                        cntBit <= 10;
                        tx <= 1;
                    end
                    else if (cntBit == 10) begin
                        cntBit <= 0; 
                        transm_rdy <= 1; 
                        state <= 2'b00; 
                    end 
                end 
            end 
        endcase 
    end 
endmodule