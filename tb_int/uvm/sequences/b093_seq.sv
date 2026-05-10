`ifndef RDMA_SUBSYSTEM_SEQ_B093_SV
`define RDMA_SUBSYSTEM_SEQ_B093_SV

class seq_b093 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b093)

  function new(string name = "seq_b093");
    super.new(name);
    set_case_id("B093");
  endfunction
endclass

`endif
