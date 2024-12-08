module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/jingcao/Desktop/ObNoDog/sim_build/temp_ccl.fst");
    $dumpvars(0, temp_ccl);
end
endmodule
