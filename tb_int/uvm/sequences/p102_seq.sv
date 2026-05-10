`ifndef RDMA_SUBSYSTEM_SEQ_P102_SV
`define RDMA_SUBSYSTEM_SEQ_P102_SV

class seq_p102 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p102)

  function new(string name = "seq_p102");
    super.new(name);
    set_case_id("P102");
  endfunction
endclass

`endif
