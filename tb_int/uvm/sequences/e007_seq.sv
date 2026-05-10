`ifndef RDMA_SUBSYSTEM_SEQ_E007_SV
`define RDMA_SUBSYSTEM_SEQ_E007_SV

class seq_e007 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e007)

  function new(string name = "seq_e007");
    super.new(name);
    set_case_id("E007");
  endfunction
endclass

`endif
