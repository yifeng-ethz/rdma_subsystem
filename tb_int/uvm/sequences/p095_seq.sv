`ifndef RDMA_SUBSYSTEM_SEQ_P095_SV
`define RDMA_SUBSYSTEM_SEQ_P095_SV

class seq_p095 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p095)

  function new(string name = "seq_p095");
    super.new(name);
    set_case_id("P095");
  endfunction
endclass

`endif
