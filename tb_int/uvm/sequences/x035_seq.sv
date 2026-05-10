`ifndef RDMA_SUBSYSTEM_SEQ_X035_SV
`define RDMA_SUBSYSTEM_SEQ_X035_SV

class seq_x035 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x035)

  function new(string name = "seq_x035");
    super.new(name);
    set_case_id("X035");
  endfunction
endclass

`endif
