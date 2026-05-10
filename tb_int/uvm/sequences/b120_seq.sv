`ifndef RDMA_SUBSYSTEM_SEQ_B120_SV
`define RDMA_SUBSYSTEM_SEQ_B120_SV

class seq_b120 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b120)

  function new(string name = "seq_b120");
    super.new(name);
    set_case_id("B120");
  endfunction
endclass

`endif
