module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/jingcao/Desktop/ObNoDog/sim_build/moore_neighbor_tracing.fst");
    $dumpvars(0, moore_neighbor_tracing);
end
endmodule
