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
