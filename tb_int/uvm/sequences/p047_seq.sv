`ifndef RDMA_SUBSYSTEM_SEQ_P047_SV
`define RDMA_SUBSYSTEM_SEQ_P047_SV

class seq_p047 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p047)

  function new(string name = "seq_p047");
    super.new(name);
    set_case_id("P047");
  endfunction
endclass

`endif
