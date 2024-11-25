module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/jingcao/Desktop/ObNoDog/sim_build/kmeans.fst");
    $dumpvars(0, kmeans);
end
endmodule
