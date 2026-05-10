`ifndef RDMA_SUBSYSTEM_SEQ_P015_SV
`define RDMA_SUBSYSTEM_SEQ_P015_SV

class seq_p015 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p015)

  function new(string name = "seq_p015");
    super.new(name);
    set_case_id("P015");
  endfunction
endclass

`endif
