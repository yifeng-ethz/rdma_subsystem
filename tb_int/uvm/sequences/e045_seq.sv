`ifndef RDMA_SUBSYSTEM_SEQ_E045_SV
`define RDMA_SUBSYSTEM_SEQ_E045_SV

class seq_e045 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e045)

  function new(string name = "seq_e045");
    super.new(name);
    set_case_id("E045");
  endfunction
endclass

`endif
