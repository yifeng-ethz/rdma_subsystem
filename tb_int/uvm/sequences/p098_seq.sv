`ifndef RDMA_SUBSYSTEM_SEQ_P098_SV
`define RDMA_SUBSYSTEM_SEQ_P098_SV

class seq_p098 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p098)

  function new(string name = "seq_p098");
    super.new(name);
    set_case_id("P098");
  endfunction
endclass

`endif
