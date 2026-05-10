`ifndef RDMA_SUBSYSTEM_SEQ_B007_SV
`define RDMA_SUBSYSTEM_SEQ_B007_SV

class seq_b007 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b007)

  function new(string name = "seq_b007");
    super.new(name);
    set_case_id("B007");
  endfunction
endclass

`endif
