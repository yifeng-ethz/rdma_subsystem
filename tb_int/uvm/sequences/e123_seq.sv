`ifndef RDMA_SUBSYSTEM_SEQ_E123_SV
`define RDMA_SUBSYSTEM_SEQ_E123_SV

class seq_e123 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e123)

  function new(string name = "seq_e123");
    super.new(name);
    set_case_id("E123");
  endfunction
endclass

`endif
