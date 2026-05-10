`ifndef RDMA_SUBSYSTEM_SEQ_E076_SV
`define RDMA_SUBSYSTEM_SEQ_E076_SV

class seq_e076 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e076)

  function new(string name = "seq_e076");
    super.new(name);
    set_case_id("E076");
  endfunction
endclass

`endif
