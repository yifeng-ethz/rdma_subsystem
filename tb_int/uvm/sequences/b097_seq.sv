`ifndef RDMA_SUBSYSTEM_SEQ_B097_SV
`define RDMA_SUBSYSTEM_SEQ_B097_SV

class seq_b097 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b097)

  function new(string name = "seq_b097");
    super.new(name);
    set_case_id("B097");
  endfunction
endclass

`endif
