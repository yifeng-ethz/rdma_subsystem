`ifndef RDMA_SUBSYSTEM_SEQ_P071_SV
`define RDMA_SUBSYSTEM_SEQ_P071_SV

class seq_p071 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p071)

  function new(string name = "seq_p071");
    super.new(name);
    set_case_id("P071");
  endfunction
endclass

`endif
