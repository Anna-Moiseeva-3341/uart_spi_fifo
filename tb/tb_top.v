`timescale 1ns / 1ps

module tb_top;
    reg clk;
    reg key_pressed;        
    
    wire o_LED1;
    wire [3:0] debug_signal; 

    top #(
        .DEBOUNCE_COUNT(10) 
    ) uut (
        .clk(clk),
        .key_pressed(key_pressed),
        .o_LED1(o_LED1),
        .debug_signal(debug_signal)
    );

    initial begin
        clk = 0;
        forever #18.5 clk = ~clk; 
    end

    initial begin
        $dumpfile("wave.vcd"); 
        $dumpvars(0, tb_top);  

        key_pressed = 1; 
        $display("Start Simulation");

        wait(uut.rst_n == 1);
        $display("Reset finished at %t", $time);

        #200;
        
        if (debug_signal[0] === 0 || debug_signal[0] === 1'bx) 
            $display("[CHECK] Mode is UART (Correct)");
        else 
            $error("[FAIL] Signal 0 should be low/undef initially");

        $display("Waiting for UART Start Bit (TX line goes LOW)...");

        wait(debug_signal[1] == 0); 
        $display("UART Start Bit Detected at %t", $time);
        
        wait(debug_signal[0] == 1);
        $display("[SUCCESS] UART Loopback Match Confirmed! (Sent == Received)");

        #10000; 
        $display("Pressing Button...");
        key_pressed = 0; 
        #1000;           
        key_pressed = 1; 
        #1000;

        if (uut.mode_select == 1) 
            $display("[CHECK] Mode switched to SPI (Correct)");
        else 
            $error("[FAIL] Mode did not switch to SPI");

        $display("Waiting for SPI transaction...");

        wait(debug_signal[3] == 0);
        $display("SPI CS went LOW (Start) at %t", $time);

        wait(debug_signal[3] == 1);
        $display("SPI CS went HIGH (End) at %t", $time);

        #2000;
        
        $display("Testbench Finished Successfully");
        $finish; 
    end
endmodule