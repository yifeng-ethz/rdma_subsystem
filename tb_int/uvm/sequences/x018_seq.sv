`ifndef RDMA_SUBSYSTEM_SEQ_X018_SV
`define RDMA_SUBSYSTEM_SEQ_X018_SV

class seq_x018 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x018)

  function new(string name = "seq_x018");
    super.new(name);
    set_case_id("X018");
  endfunction
endclass

`endif
