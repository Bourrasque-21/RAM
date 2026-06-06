`include "uvm_macros.svh"
import uvm_pkg::*;

// === interface
interface ram_if (
    input logic clk
);
    logic        we;
    logic [ 7:0] addr;
    logic [15:0] wdata;
    logic [15:0] rdata;
endinterface  //ram_if

// === sequence item
class ram_seq_item extends uvm_sequence_item;
    rand bit        we;
    rand bit [ 7:0] addr;
    rand bit [15:0] wdata;
    logic    [15:0] rdata;

    // -- Constraint 
    /*
    constraint c_we {
        we dist {
            1 := 1,
            0 := 0
        };
    }
    constraint c_addr {addr inside {[0 : 9]};}
    // constraint c_wdata
    */

    `uvm_object_utils_begin(ram_seq_item)
        `uvm_field_int(we, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "ram_seq_item");
        super.new(name);
    endfunction  //new()
endclass  //ram_seq_item extends uvm_sequence_item

// === sequence
class ram_seq extends uvm_sequence #(ram_seq_item);
    `uvm_object_utils(ram_seq)

    function new(string name = "ram_seq");
        super.new(name);
    endfunction  //new()

    virtual task body();
        ram_seq_item item;
        repeat (1000) begin
            item = ram_seq_item::type_id::create("item");
            start_item(item);
            assert (item.randomize());
            finish_item(item);
        end
    endtask  //body
endclass  //ram_seq extends uvm_sequence

// === driver
class ram_driver extends uvm_driver #(ram_seq_item);
    `uvm_component_utils(ram_driver)

    virtual ram_if r_if;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ram_if)::get(this, "", "r_if", r_if))
            `uvm_fatal(get_type_name(), "cannnot found r_if!")
        `uvm_info(get_type_name(), "build phase executed", UVM_HIGH);
    endfunction

    virtual task run_phase(uvm_phase phase);
        ram_seq_item item;
        forever begin
            seq_item_port.get_next_item(item);
            @(negedge r_if.clk);
            r_if.we    <= item.we;
            r_if.addr  <= item.addr;
            r_if.wdata <= item.wdata;
            seq_item_port.item_done();
        end
    endtask  //run_phase
endclass  //ram_driver extends uvm_driver

// === monitor
class ram_monitor extends uvm_monitor;
    `uvm_component_utils(ram_monitor)

    uvm_analysis_port #(ram_seq_item) send;

    virtual ram_if r_if;
    ram_seq_item r_seq_item;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        send = new("WRITE", this);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ram_if)::get(this, "", "r_if", r_if))
            `uvm_fatal(get_type_name(), "cannot found r_if!")
        `uvm_info(get_type_name(), "build phase executed", UVM_HIGH);
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            @(posedge r_if.clk);
            #1;
            r_seq_item = ram_seq_item::type_id::create("item", this);
            r_seq_item.we    = r_if.we;
            r_seq_item.addr  = r_if.addr;
            r_seq_item.wdata = r_if.wdata;
            r_seq_item.rdata = r_if.rdata;
            `uvm_info(get_type_name(), $sformatf(
                      "sampled RAM transaction addr: %0h, wdata: %0h, rdata: %0h",
                      r_if.addr,
                      r_if.wdata,
                      r_if.rdata
                      ), UVM_HIGH);
            send.write(r_seq_item);
        end
    endtask  //run_phase
endclass  //ram_monitor extends uvm_monitor

// === subscriber
class ram_coverage extends uvm_subscriber #(ram_seq_item);
    `uvm_component_utils(ram_coverage)

    ram_seq_item item;

    covergroup ram_cg;
        cp_we: coverpoint item.we {bins we_0 = {0}; bins we_1 = {1};}
        cp_addr: coverpoint item.addr {
            bins low = {[0 : 63]};
            bins mid1 = {[64 : 127]};
            bins mid2 = {[128 : 191]};
            bins high = {[192 : 255]};
        }
        cp_wdata: coverpoint item.wdata;
        cx_we_addr: cross cp_we, cp_addr;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ram_cg = new();
    endfunction  //new()

    virtual function void write(ram_seq_item t);
        item = t;
        ram_cg.sample();
        // `uvm_info(get_type_name(), $sformatf("counter_cg sampled: %s", item.convert2string()), UVM_MEDIUM)
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "==== RAM Coverage Summary ====", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(
                  "cp_we       : %0.2f%%", ram_cg.cp_we.get_coverage()),
                  UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(
                  "cp_addr     : %0.2f%%", ram_cg.cp_addr.get_coverage()),
                  UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(
                  "cp_wdata    : %0.2f%%", ram_cg.cp_wdata.get_coverage()),
                  UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(
                  "cx_we_addr  : %0.2f%%", ram_cg.cx_we_addr.get_coverage()),
                  UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(
                  "total       : %0.2f%%", ram_cg.get_coverage()), UVM_LOW)
    endfunction
endclass  //ram_coverage extends uvm_subscriber


// === scoreboard
class ram_scb extends uvm_scoreboard;
    `uvm_component_utils(ram_scb)

    uvm_analysis_imp #(ram_seq_item, ram_scb) recv;

    logic [15:0] ref_mem[0:255];
    logic [15:0] exp_rdata;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        recv = new("READ", this);
    endfunction  //new()

    virtual function void write(ram_seq_item data);
        exp_rdata = ref_mem[data.addr];
        if (data.rdata === exp_rdata) begin
            `uvm_info(
                get_type_name(),
                $sformatf(
                    "[PASS] we = %0b, addr: %0h, wdata: %0h, exp_rdata: %0h == rdata: %0h",
                    data.we, data.addr, data.wdata, exp_rdata, data.rdata),
                UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf(
                       "[FAIL] we = %0b, addr: %0h, wdata: %0h, exp_rdata: %0h != rdata: %0h",
                       data.we,
                       data.addr,
                       data.wdata,
                       exp_rdata,
                       data.rdata
                       ))
        end
        if (data.we) begin
            ref_mem[data.addr] = data.wdata;
        end
    endfunction
endclass  //ram_scb extends uvm_scoreboard

// === agent
class ram_agent extends uvm_agent;
    `uvm_component_utils(ram_agent)

    uvm_sequencer #(ram_seq_item) sqr;
    ram_driver drv;
    ram_monitor mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sqr = uvm_sequencer#(ram_seq_item)::type_id::create("sqr", this);
        drv = ram_driver::type_id::create("drv", this);
        mon = ram_monitor::type_id::create("mon", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass  //ram_agent extends uvm_agent

// === environment
class ram_env extends uvm_env;
    `uvm_component_utils(ram_env)

    ram_agent agt;
    ram_scb scb;
    ram_coverage sbr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = ram_agent::type_id::create("agt", this);
        scb = ram_scb::type_id::create("scb", this);
        sbr = ram_coverage::type_id::create("sbr", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.send.connect(scb.recv);
        agt.mon.send.connect(sbr.analysis_export);
    endfunction
endclass  //ram_env extends uvm_env

// === test
class ram_test extends uvm_test;
    `uvm_component_utils(ram_test)

    ram_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ram_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        ram_seq seq;
        phase.raise_objection(this);
        seq = ram_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        phase.drop_objection(this);
    endtask

    virtual function void report_phase(uvm_phase phase);
        uvm_report_server svr = uvm_report_server::get_server();
        if (svr.get_severity_count(UVM_ERROR) == 0)
            `uvm_info(get_type_name(), "===== TEST PASS! =====", UVM_LOW)
        else `uvm_info(get_type_name(), "===== TEST FAIL! =====", UVM_LOW)
    endfunction
endclass  //ram_test extends uvm_test

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
endmodule
