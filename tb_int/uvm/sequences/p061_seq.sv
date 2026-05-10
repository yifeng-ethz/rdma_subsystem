`ifndef RDMA_SUBSYSTEM_SEQ_P061_SV
`define RDMA_SUBSYSTEM_SEQ_P061_SV

class seq_p061 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p061)

  function new(string name = "seq_p061");
    super.new(name);
    set_case_id("P061");
  endfunction
endclass

`endif
