`ifndef RDMA_SUBSYSTEM_SEQ_E012_SV
`define RDMA_SUBSYSTEM_SEQ_E012_SV

class seq_e012 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e012)

  function new(string name = "seq_e012");
    super.new(name);
    set_case_id("E012");
  endfunction
endclass

`endif
