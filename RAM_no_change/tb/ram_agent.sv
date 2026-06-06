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
