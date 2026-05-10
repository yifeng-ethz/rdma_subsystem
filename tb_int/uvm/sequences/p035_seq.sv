`ifndef RDMA_SUBSYSTEM_SEQ_P035_SV
`define RDMA_SUBSYSTEM_SEQ_P035_SV

class seq_p035 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p035)

  function new(string name = "seq_p035");
    super.new(name);
    set_case_id("P035");
  endfunction
endclass

`endif
