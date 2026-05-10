`ifndef RDMA_SUBSYSTEM_SEQ_B018_SV
`define RDMA_SUBSYSTEM_SEQ_B018_SV

class seq_b018 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b018)

  function new(string name = "seq_b018");
    super.new(name);
    set_case_id("B018");
  endfunction
endclass

`endif
