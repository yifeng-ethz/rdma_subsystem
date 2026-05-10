`ifndef RDMA_SUBSYSTEM_SEQ_B033_SV
`define RDMA_SUBSYSTEM_SEQ_B033_SV

class seq_b033 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b033)

  function new(string name = "seq_b033");
    super.new(name);
    set_case_id("B033");
  endfunction
endclass

`endif
