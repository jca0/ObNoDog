module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/jingcao/Desktop/6.205/lab07/sim_build/convolution.fst");
    $dumpvars(0, convolution);
end
endmodule
