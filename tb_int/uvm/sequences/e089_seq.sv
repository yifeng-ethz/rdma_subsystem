`ifndef RDMA_SUBSYSTEM_SEQ_E089_SV
`define RDMA_SUBSYSTEM_SEQ_E089_SV

class seq_e089 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e089)

  function new(string name = "seq_e089");
    super.new(name);
    set_case_id("E089");
  endfunction
endclass

`endif
