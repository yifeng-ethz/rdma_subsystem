`ifndef RDMA_SUBSYSTEM_SEQ_E093_SV
`define RDMA_SUBSYSTEM_SEQ_E093_SV

class seq_e093 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e093)

  function new(string name = "seq_e093");
    super.new(name);
    set_case_id("E093");
  endfunction
endclass

`endif
