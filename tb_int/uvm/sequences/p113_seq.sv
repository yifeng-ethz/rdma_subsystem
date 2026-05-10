`ifndef RDMA_SUBSYSTEM_SEQ_P113_SV
`define RDMA_SUBSYSTEM_SEQ_P113_SV

class seq_p113 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p113)

  function new(string name = "seq_p113");
    super.new(name);
    set_case_id("P113");
  endfunction
endclass

`endif
