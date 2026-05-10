`ifndef RDMA_SUBSYSTEM_SEQ_B020_SV
`define RDMA_SUBSYSTEM_SEQ_B020_SV

class seq_b020 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b020)

  function new(string name = "seq_b020");
    super.new(name);
    set_case_id("B020");
  endfunction
endclass

`endif
