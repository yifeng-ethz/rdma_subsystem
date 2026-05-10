`ifndef RDMA_SUBSYSTEM_SEQ_P022_SV
`define RDMA_SUBSYSTEM_SEQ_P022_SV

class seq_p022 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p022)

  function new(string name = "seq_p022");
    super.new(name);
    set_case_id("P022");
  endfunction
endclass

`endif
