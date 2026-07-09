`timescale 1ns/1ps

module tb_nand_gate ();

    reg t_a;
    reg t_b;
    wire w_y;

    nand_gate UUT (
        .a(t_a),
        .b(t_b),
        .y(w_y)
    );

    initial begin
        $dumpfile("simulasi_nand.vcd");         
        $dumpvars(0, tb_nand_gate);
        $monitor("Time = %0t ns | A = %b | B = %b | NAND Output (Y) = %b", $time, t_a, t_b, w_y);
        t_a = 0; t_b = 0; #10;
        t_a = 0; t_b = 1; #10;
        t_a = 1; t_b = 0; #10;
        t_a = 1; t_b = 1; #10;
    end
    
endmodule