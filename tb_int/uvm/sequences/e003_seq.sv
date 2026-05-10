`ifndef RDMA_SUBSYSTEM_SEQ_E003_SV
`define RDMA_SUBSYSTEM_SEQ_E003_SV

class seq_e003 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e003)

  function new(string name = "seq_e003");
    super.new(name);
    set_case_id("E003");
  endfunction
endclass

`endif
