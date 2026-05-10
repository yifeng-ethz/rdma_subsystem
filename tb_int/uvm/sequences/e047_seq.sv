`ifndef RDMA_SUBSYSTEM_SEQ_E047_SV
`define RDMA_SUBSYSTEM_SEQ_E047_SV

class seq_e047 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e047)

  function new(string name = "seq_e047");
    super.new(name);
    set_case_id("E047");
  endfunction
endclass

`endif
