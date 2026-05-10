`ifndef RDMA_SUBSYSTEM_SEQ_B022_SV
`define RDMA_SUBSYSTEM_SEQ_B022_SV

class seq_b022 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b022)

  function new(string name = "seq_b022");
    super.new(name);
    set_case_id("B022");
  endfunction
endclass

`endif
