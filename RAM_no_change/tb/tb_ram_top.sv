`timescale 1ns / 1ps
import uvm_pkg::*;
import ram_uvm_pkg::*;

// === DUT
module tb_ram ();
    logic clk;

    always #5 clk = ~clk;

    ram_if r_if (clk);

    RAM dut (
        .clk  (clk),
        .we   (r_if.we),
        .addr (r_if.addr),
        .wdata(r_if.wdata),
        .rdata(r_if.rdata)
    );

    initial begin
        clk = 0;
        uvm_config_db#(virtual ram_if)::set(null, "*", "r_if", r_if);
        run_test("ram_test");
    end

    initial begin
        $fsdbDumpfile("novas.fsdb");
        $fsdbDumpvars(0, tb_ram, "+all");
    end
endmodule
