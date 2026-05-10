`ifndef RDMA_SUBSYSTEM_SEQ_P118_SV
`define RDMA_SUBSYSTEM_SEQ_P118_SV

class seq_p118 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p118)

  function new(string name = "seq_p118");
    super.new(name);
    set_case_id("P118");
  endfunction
endclass

`endif
