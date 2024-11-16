module cocotb_iverilog_dump();
initial begin
    $dumpfile("C:/Users/nicho/OneDrive/Documents/MIT/Classes/6.205/Final Project/ObNoDog/sim/sim_build/circularity.fst");
    $dumpvars(0, circularity);
end
endmodule
