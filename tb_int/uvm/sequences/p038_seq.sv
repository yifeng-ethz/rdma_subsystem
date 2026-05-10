`ifndef RDMA_SUBSYSTEM_SEQ_P038_SV
`define RDMA_SUBSYSTEM_SEQ_P038_SV

class seq_p038 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p038)

  function new(string name = "seq_p038");
    super.new(name);
    set_case_id("P038");
  endfunction
endclass

`endif
