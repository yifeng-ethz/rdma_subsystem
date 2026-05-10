`ifndef RDMA_SUBSYSTEM_SEQ_E020_SV
`define RDMA_SUBSYSTEM_SEQ_E020_SV

class seq_e020 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e020)

  function new(string name = "seq_e020");
    super.new(name);
    set_case_id("E020");
  endfunction
endclass

`endif
