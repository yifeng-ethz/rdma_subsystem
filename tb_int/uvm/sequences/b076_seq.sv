`ifndef RDMA_SUBSYSTEM_SEQ_B076_SV
`define RDMA_SUBSYSTEM_SEQ_B076_SV

class seq_b076 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b076)

  function new(string name = "seq_b076");
    super.new(name);
    set_case_id("B076");
  endfunction
endclass

`endif
