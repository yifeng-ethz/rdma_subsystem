`ifndef RDMA_SUBSYSTEM_SEQ_E010_SV
`define RDMA_SUBSYSTEM_SEQ_E010_SV

class seq_e010 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e010)

  function new(string name = "seq_e010");
    super.new(name);
    set_case_id("E010");
  endfunction
endclass

`endif
