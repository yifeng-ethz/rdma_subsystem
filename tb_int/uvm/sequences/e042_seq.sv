`ifndef RDMA_SUBSYSTEM_SEQ_E042_SV
`define RDMA_SUBSYSTEM_SEQ_E042_SV

class seq_e042 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e042)

  function new(string name = "seq_e042");
    super.new(name);
    set_case_id("E042");
  endfunction
endclass

`endif
