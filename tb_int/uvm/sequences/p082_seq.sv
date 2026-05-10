`ifndef RDMA_SUBSYSTEM_SEQ_P082_SV
`define RDMA_SUBSYSTEM_SEQ_P082_SV

class seq_p082 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p082)

  function new(string name = "seq_p082");
    super.new(name);
    set_case_id("P082");
  endfunction
endclass

`endif
