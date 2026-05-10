`ifndef RDMA_SUBSYSTEM_SEQ_E113_SV
`define RDMA_SUBSYSTEM_SEQ_E113_SV

class seq_e113 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e113)

  function new(string name = "seq_e113");
    super.new(name);
    set_case_id("E113");
  endfunction
endclass

`endif
