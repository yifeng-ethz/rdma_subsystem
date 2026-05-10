`ifndef RDMA_SUBSYSTEM_SEQ_P107_SV
`define RDMA_SUBSYSTEM_SEQ_P107_SV

class seq_p107 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p107)

  function new(string name = "seq_p107");
    super.new(name);
    set_case_id("P107");
  endfunction
endclass

`endif
