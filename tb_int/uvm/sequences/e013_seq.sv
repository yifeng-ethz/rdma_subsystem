`ifndef RDMA_SUBSYSTEM_SEQ_E013_SV
`define RDMA_SUBSYSTEM_SEQ_E013_SV

class seq_e013 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e013)

  function new(string name = "seq_e013");
    super.new(name);
    set_case_id("E013");
  endfunction
endclass

`endif
