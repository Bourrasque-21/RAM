// === sequence item
class ram_seq_item extends uvm_sequence_item;
    rand bit        we;
    rand bit [ 7:0] addr;
    rand bit [15:0] wdata;
    logic    [15:0] rdata;

    // -- Constraint 
    // constraint c_we   {we dist {1 := 1, 0 := 0};}
    // constraint c_addr {addr inside {[8'h00 : 8'h0f]};}

    `uvm_object_utils_begin(ram_seq_item)
        `uvm_field_int(we, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "ram_seq_item");
        super.new(name);
    endfunction  //new()

    function string convert2string();
        return $sformatf(
            "[%s] addr = 0x%02h wdata = 0x%04h rdata=0x%04h",
            we ? "WRITE" : "READ ",
            addr,
            wdata,
            rdata
        );
    endfunction
endclass  //ram_seq_item extends uvm_sequence_item
