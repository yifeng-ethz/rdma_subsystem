`ifndef RDMA_SUBSYSTEM_SEQ_B031_SV
`define RDMA_SUBSYSTEM_SEQ_B031_SV

class seq_b031 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b031)

  function new(string name = "seq_b031");
    super.new(name);
    set_case_id("B031");
  endfunction
endclass

`endif
