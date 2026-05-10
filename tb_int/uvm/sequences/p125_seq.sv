`ifndef RDMA_SUBSYSTEM_SEQ_P125_SV
`define RDMA_SUBSYSTEM_SEQ_P125_SV

class seq_p125 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p125)

  function new(string name = "seq_p125");
    super.new(name);
    set_case_id("P125");
  endfunction
endclass

`endif
