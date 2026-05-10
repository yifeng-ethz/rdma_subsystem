`ifndef RDMA_SUBSYSTEM_SEQ_P028_SV
`define RDMA_SUBSYSTEM_SEQ_P028_SV

class seq_p028 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p028)

  function new(string name = "seq_p028");
    super.new(name);
    set_case_id("P028");
  endfunction
endclass

`endif
