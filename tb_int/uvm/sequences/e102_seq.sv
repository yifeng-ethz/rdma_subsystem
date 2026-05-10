`ifndef RDMA_SUBSYSTEM_SEQ_E102_SV
`define RDMA_SUBSYSTEM_SEQ_E102_SV

class seq_e102 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e102)

  function new(string name = "seq_e102");
    super.new(name);
    set_case_id("E102");
  endfunction
endclass

`endif
