// === scoreboard
class ram_scb extends uvm_scoreboard;
    `uvm_component_utils(ram_scb)

    virtual ram_if r_if;
    uvm_analysis_imp #(ram_seq_item, ram_scb) recv;

    logic [15:0] ref_mem[0:255];
    logic [15:0] exp_rdata;
    logic [15:0] prev_rdata;
    int pass_count;
    int fail_count;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        recv = new("READ", this);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ram_if)::get(this, "", "r_if", r_if))
            `uvm_fatal(get_type_name(), "cannnot found r_if!")
        `uvm_info(get_type_name(), "build phase executed", UVM_HIGH);
    endfunction

    virtual function void write(ram_seq_item data);
        if (data.we) begin
            exp_rdata = prev_rdata;
            ref_mem[data.addr] = data.wdata;
        end else begin
            exp_rdata = ref_mem[data.addr];
        end
        prev_rdata = data.rdata;
        if (data.rdata === exp_rdata) begin
            `uvm_info(
                get_type_name(),
                $sformatf(
                    "[PASS] we = %0b, addr: %0h, wdata: %0h, exp_rdata: %0h == rdata: %0h",
                    data.we, data.addr, data.wdata, exp_rdata, data.rdata),
                UVM_LOW)
            pass_count++;
        end else begin
            `uvm_error(get_type_name(), $sformatf(
                       "[FAIL] we = %0b, addr: %0h, wdata: %0h, exp_rdata: %0h != rdata: %0h",
                       data.we,
                       data.addr,
                       data.wdata,
                       exp_rdata,
                       data.rdata
                       ))
            fail_count++;
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), "===== Report Summary =====", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(
                  " Total transaction: %0d", pass_count + fail_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(" Matches: %0d", pass_count),
                  UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(" Error: %0d", fail_count),
                  UVM_LOW)
        if (fail_count > 0) begin
            `uvm_info(get_type_name(),
                      $sformatf(" Test Failed: %0d mismatches detected",
                                fail_count), UVM_LOW)
        end else begin
            `uvm_info(get_type_name(), $sformatf(
                      " Test Passed: %0d all matches detected", pass_count),
                      UVM_LOW)
        end
    endfunction
endclass  //ram_scb extends uvm_scoreboard
