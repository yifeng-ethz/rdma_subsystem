`ifndef RDMA_SUBSYSTEM_SEQ_P091_SV
`define RDMA_SUBSYSTEM_SEQ_P091_SV

class seq_p091 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p091)

  function new(string name = "seq_p091");
    super.new(name);
    set_case_id("P091");
  endfunction
endclass

`endif
