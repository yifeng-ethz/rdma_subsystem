`ifndef RDMA_SUBSYSTEM_SEQ_E064_SV
`define RDMA_SUBSYSTEM_SEQ_E064_SV

class seq_e064 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e064)

  function new(string name = "seq_e064");
    super.new(name);
    set_case_id("E064");
  endfunction
endclass

`endif
