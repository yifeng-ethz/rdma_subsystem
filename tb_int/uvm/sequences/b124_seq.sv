`ifndef RDMA_SUBSYSTEM_SEQ_B124_SV
`define RDMA_SUBSYSTEM_SEQ_B124_SV

class seq_b124 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b124)

  function new(string name = "seq_b124");
    super.new(name);
    set_case_id("B124");
  endfunction
endclass

`endif
