`ifndef RDMA_SUBSYSTEM_SEQ_B091_SV
`define RDMA_SUBSYSTEM_SEQ_B091_SV

class seq_b091 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b091)

  function new(string name = "seq_b091");
    super.new(name);
    set_case_id("B091");
  endfunction
endclass

`endif
