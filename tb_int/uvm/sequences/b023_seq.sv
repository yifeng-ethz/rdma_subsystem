`ifndef RDMA_SUBSYSTEM_SEQ_B023_SV
`define RDMA_SUBSYSTEM_SEQ_B023_SV

class seq_b023 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b023)

  function new(string name = "seq_b023");
    super.new(name);
    set_case_id("B023");
  endfunction
endclass

`endif
