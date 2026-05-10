`ifndef RDMA_SUBSYSTEM_SEQ_E015_SV
`define RDMA_SUBSYSTEM_SEQ_E015_SV

class seq_e015 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e015)

  function new(string name = "seq_e015");
    super.new(name);
    set_case_id("E015");
  endfunction
endclass

`endif
