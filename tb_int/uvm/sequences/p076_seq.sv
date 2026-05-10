`ifndef RDMA_SUBSYSTEM_SEQ_P076_SV
`define RDMA_SUBSYSTEM_SEQ_P076_SV

class seq_p076 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p076)

  function new(string name = "seq_p076");
    super.new(name);
    set_case_id("P076");
  endfunction
endclass

`endif
