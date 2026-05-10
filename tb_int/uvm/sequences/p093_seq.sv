`ifndef RDMA_SUBSYSTEM_SEQ_P093_SV
`define RDMA_SUBSYSTEM_SEQ_P093_SV

class seq_p093 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p093)

  function new(string name = "seq_p093");
    super.new(name);
    set_case_id("P093");
  endfunction
endclass

`endif
