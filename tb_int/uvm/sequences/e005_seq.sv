`ifndef RDMA_SUBSYSTEM_SEQ_E005_SV
`define RDMA_SUBSYSTEM_SEQ_E005_SV

class seq_e005 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e005)

  function new(string name = "seq_e005");
    super.new(name);
    set_case_id("E005");
  endfunction
endclass

`endif
