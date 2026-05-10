`ifndef RDMA_SUBSYSTEM_SEQ_P085_SV
`define RDMA_SUBSYSTEM_SEQ_P085_SV

class seq_p085 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p085)

  function new(string name = "seq_p085");
    super.new(name);
    set_case_id("P085");
  endfunction
endclass

`endif
