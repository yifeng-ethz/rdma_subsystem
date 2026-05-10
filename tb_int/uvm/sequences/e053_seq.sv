`ifndef RDMA_SUBSYSTEM_SEQ_E053_SV
`define RDMA_SUBSYSTEM_SEQ_E053_SV

class seq_e053 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e053)

  function new(string name = "seq_e053");
    super.new(name);
    set_case_id("E053");
  endfunction
endclass

`endif
