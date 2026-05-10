`ifndef RDMA_SUBSYSTEM_SEQ_B016_SV
`define RDMA_SUBSYSTEM_SEQ_B016_SV

class seq_b016 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b016)

  function new(string name = "seq_b016");
    super.new(name);
    set_case_id("B016");
  endfunction
endclass

`endif
