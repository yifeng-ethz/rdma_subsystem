`ifndef RDMA_SUBSYSTEM_SEQ_P124_SV
`define RDMA_SUBSYSTEM_SEQ_P124_SV

class seq_p124 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p124)

  function new(string name = "seq_p124");
    super.new(name);
    set_case_id("P124");
  endfunction
endclass

`endif
