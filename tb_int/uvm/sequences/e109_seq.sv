`ifndef RDMA_SUBSYSTEM_SEQ_E109_SV
`define RDMA_SUBSYSTEM_SEQ_E109_SV

class seq_e109 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e109)

  function new(string name = "seq_e109");
    super.new(name);
    set_case_id("E109");
  endfunction
endclass

`endif
