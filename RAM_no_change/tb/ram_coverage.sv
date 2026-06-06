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
