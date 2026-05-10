`ifndef RDMA_SUBSYSTEM_SEQ_E065_SV
`define RDMA_SUBSYSTEM_SEQ_E065_SV

class seq_e065 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e065)

  function new(string name = "seq_e065");
    super.new(name);
    set_case_id("E065");
  endfunction
endclass

`endif
