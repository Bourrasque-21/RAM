// === test 1 : random test
class ram_test extends uvm_test;
    `uvm_component_utils(ram_test)

    virtual ram_if r_if;
    ram_env env;
    ram_base_seq seq;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ram_env::type_id::create("env", this);
        if (!uvm_config_db#(virtual ram_if)::get(this, "", "r_if", r_if))
            `uvm_fatal(get_type_name(), "cannot found r_if!")
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq = ram_base_seq::type_id::create("seq");
        seq.num_transaction = 100;
        seq.start(env.agt.sqr);
        @(r_if.mon_cb);
        phase.drop_objection(this);
    endtask

    virtual function void report_phase(uvm_phase phase);
        uvm_report_server svr = uvm_report_server::get_server();
        if (svr.get_severity_count(UVM_ERROR) == 0)
            `uvm_info(get_type_name(), "===== TEST PASS! =====", UVM_LOW)
        else `uvm_info(get_type_name(), "===== TEST FAIL! =====", UVM_LOW)
    endfunction
endclass  //ram_test extends uvm_test


// === test 2 : read -> write -> read on same address
class ram_test_2 extends ram_test;
    `uvm_component_utils(ram_test_2)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq = ram_seq_2::type_id::create("seq");
        seq.num_transaction = 100;
        seq.start(env.agt.sqr);
        @(r_if.mon_cb);
        phase.drop_objection(this);
    endtask
endclass  //ram_test extends uvm_test
