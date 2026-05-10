`ifndef RDMA_SUBSYSTEM_SEQ_E022_SV
`define RDMA_SUBSYSTEM_SEQ_E022_SV

class seq_e022 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e022)

  function new(string name = "seq_e022");
    super.new(name);
    set_case_id("E022");
  endfunction
endclass

`endif
