`ifndef RDMA_SUBSYSTEM_SEQ_P084_SV
`define RDMA_SUBSYSTEM_SEQ_P084_SV

class seq_p084 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p084)

  function new(string name = "seq_p084");
    super.new(name);
    set_case_id("P084");
  endfunction
endclass

`endif
