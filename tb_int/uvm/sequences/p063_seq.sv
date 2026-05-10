`ifndef RDMA_SUBSYSTEM_SEQ_P063_SV
`define RDMA_SUBSYSTEM_SEQ_P063_SV

class seq_p063 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p063)

  function new(string name = "seq_p063");
    super.new(name);
    set_case_id("P063");
  endfunction
endclass

`endif
