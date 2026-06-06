// === driver
class ram_driver extends uvm_driver #(ram_seq_item);
    `uvm_component_utils(ram_driver)

    ram_seq_item   item;
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
        forever begin
            seq_item_port.get_next_item(item);
            @(r_if.drv_cb);
            r_if.drv_cb.we    <= item.we;
            r_if.drv_cb.addr  <= item.addr;
            r_if.drv_cb.wdata <= item.wdata;
            seq_item_port.item_done();
        end
    endtask  //run_phase
endclass  //ram_driver extends uvm_driver
