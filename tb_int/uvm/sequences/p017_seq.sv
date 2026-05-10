`ifndef RDMA_SUBSYSTEM_SEQ_P017_SV
`define RDMA_SUBSYSTEM_SEQ_P017_SV

class seq_p017 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p017)

  function new(string name = "seq_p017");
    super.new(name);
    set_case_id("P017");
  endfunction
endclass

`endif
