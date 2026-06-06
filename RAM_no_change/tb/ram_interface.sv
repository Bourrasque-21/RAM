// === interface
interface ram_if (
    input logic clk
);
    logic        we;
    logic [ 7:0] addr;
    logic [15:0] wdata;
    logic [15:0] rdata;

    clocking drv_cb @(negedge clk);
        default input #1 output #0;
        output we;
        output addr;
        output wdata;
        input rdata;
    endclocking

    clocking mon_cb @(negedge clk);
        default input #1;
        input we;
        input addr;
        input wdata;
        input rdata;
    endclocking
endinterface  //ram_if
