`ifndef RDMA_SUBSYSTEM_SEQ_B034_SV
`define RDMA_SUBSYSTEM_SEQ_B034_SV

class seq_b034 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b034)

  function new(string name = "seq_b034");
    super.new(name);
    set_case_id("B034");
  endfunction
endclass

`endif
