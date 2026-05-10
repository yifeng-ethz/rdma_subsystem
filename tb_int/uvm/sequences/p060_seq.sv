`ifndef RDMA_SUBSYSTEM_SEQ_P060_SV
`define RDMA_SUBSYSTEM_SEQ_P060_SV

class seq_p060 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p060)

  function new(string name = "seq_p060");
    super.new(name);
    set_case_id("P060");
  endfunction
endclass

`endif
