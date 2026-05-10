`ifndef RDMA_SUBSYSTEM_SEQ_P122_SV
`define RDMA_SUBSYSTEM_SEQ_P122_SV

class seq_p122 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p122)

  function new(string name = "seq_p122");
    super.new(name);
    set_case_id("P122");
  endfunction
endclass

`endif
