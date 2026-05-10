`ifndef RDMA_SUBSYSTEM_SEQ_B070_SV
`define RDMA_SUBSYSTEM_SEQ_B070_SV

class seq_b070 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b070)

  function new(string name = "seq_b070");
    super.new(name);
    set_case_id("B070");
  endfunction
endclass

`endif
