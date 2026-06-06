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
        @(r_if.mon_cb);  // startup sample discard
        forever begin
            r_seq_item = ram_seq_item::type_id::create("item", this);
            @(r_if.mon_cb);
            r_seq_item.we    = r_if.mon_cb.we;
            r_seq_item.addr  = r_if.mon_cb.addr;
            r_seq_item.wdata = r_if.mon_cb.wdata;
            r_seq_item.rdata = r_if.mon_cb.rdata;
            `uvm_info(get_type_name(), r_seq_item.convert2string(), UVM_MEDIUM);
            send.write(r_seq_item);
        end
    endtask  //run_phase
endclass  //ram_monitor extends uvm_monitor
