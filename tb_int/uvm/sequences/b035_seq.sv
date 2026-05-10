`ifndef RDMA_SUBSYSTEM_SEQ_B035_SV
`define RDMA_SUBSYSTEM_SEQ_B035_SV

class seq_b035 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b035)

  function new(string name = "seq_b035");
    super.new(name);
    set_case_id("B035");
  endfunction
endclass

`endif
