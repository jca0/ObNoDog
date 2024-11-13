module cocotb_iverilog_dump();
initial begin
    $dumpfile("C:/Users/nicho/OneDrive/Documents/MIT/Classes/6.205/lab07/sim/sim_build/convolution.fst");
    $dumpvars(0, convolution);
end
endmodule
