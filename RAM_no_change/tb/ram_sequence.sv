// === sequence 1 (base) : random test
class ram_base_seq extends uvm_sequence #(ram_seq_item);
    `uvm_object_utils(ram_base_seq)

    ram_seq_item item;
    int num_transaction = 0;

    function new(string name = "ram_seq");
        super.new(name);
    endfunction  //new()

    virtual task body();
        repeat (num_transaction) begin
            item = ram_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_fatal(get_type_name(), "Randomization Failed!");
            finish_item(item);
        end
    endtask  //body
endclass  //ram_seq extends uvm_sequence


// === sequence 2 :  read -> write -> read on same address
class ram_seq_2 extends ram_base_seq;
    `uvm_object_utils(ram_seq_2)

    function new(string name = "ram_seq");
        super.new(name);
    endfunction  //new()

    virtual task body();
        repeat (num_transaction) begin
            item = ram_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {item.we == 0;})
                `uvm_fatal(get_type_name(), "Randomization Failed!");
            finish_item(item);

            start_item(item);
            item.we = 1;
            finish_item(item);

            start_item(item);
            item.we = 0;
            finish_item(item);
        end
    endtask  //body
endclass  //ram_seq extends uvm_sequence
