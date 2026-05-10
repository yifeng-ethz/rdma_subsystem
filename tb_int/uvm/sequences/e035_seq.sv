`ifndef RDMA_SUBSYSTEM_SEQ_E035_SV
`define RDMA_SUBSYSTEM_SEQ_E035_SV

class seq_e035 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e035)

  function new(string name = "seq_e035");
    super.new(name);
    set_case_id("E035");
  endfunction
endclass

`endif
