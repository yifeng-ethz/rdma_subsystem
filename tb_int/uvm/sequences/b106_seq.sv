`ifndef RDMA_SUBSYSTEM_SEQ_B106_SV
`define RDMA_SUBSYSTEM_SEQ_B106_SV

class seq_b106 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b106)

  function new(string name = "seq_b106");
    super.new(name);
    set_case_id("B106");
  endfunction
endclass

`endif
