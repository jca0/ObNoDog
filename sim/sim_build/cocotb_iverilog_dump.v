module cocotb_iverilog_dump();
initial begin
    $dumpfile("C:/Users/nicho/OneDrive/Documents/MIT/Classes/6.205/Final Project/ObNoDog/sim/sim_build/moore_neighbor_tracing_ccl_test.fst");
    $dumpvars(0, moore_neighbor_tracing_ccl_test);
end
endmodule
