`ifndef RDMA_SUBSYSTEM_SEQ_X080_SV
`define RDMA_SUBSYSTEM_SEQ_X080_SV

class seq_x080 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x080)

  function new(string name = "seq_x080");
    super.new(name);
    set_case_id("X080");
  endfunction
endclass

`endif
