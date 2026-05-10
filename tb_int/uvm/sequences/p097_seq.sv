`ifndef RDMA_SUBSYSTEM_SEQ_P097_SV
`define RDMA_SUBSYSTEM_SEQ_P097_SV

class seq_p097 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p097)

  function new(string name = "seq_p097");
    super.new(name);
    set_case_id("P097");
  endfunction
endclass

`endif
