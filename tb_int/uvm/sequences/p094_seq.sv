`ifndef RDMA_SUBSYSTEM_SEQ_P094_SV
`define RDMA_SUBSYSTEM_SEQ_P094_SV

class seq_p094 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p094)

  function new(string name = "seq_p094");
    super.new(name);
    set_case_id("P094");
  endfunction
endclass

`endif
