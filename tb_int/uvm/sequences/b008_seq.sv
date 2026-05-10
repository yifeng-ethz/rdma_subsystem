`ifndef RDMA_SUBSYSTEM_SEQ_B008_SV
`define RDMA_SUBSYSTEM_SEQ_B008_SV

class seq_b008 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b008)

  function new(string name = "seq_b008");
    super.new(name);
    set_case_id("B008");
  endfunction
endclass

`endif
