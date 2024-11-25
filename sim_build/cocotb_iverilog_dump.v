module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/jingcao/Desktop/ObNoDog/sim_build/connected_components.fst");
    $dumpvars(0, connected_components);
end
endmodule
