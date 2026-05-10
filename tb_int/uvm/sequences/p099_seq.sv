`ifndef RDMA_SUBSYSTEM_SEQ_P099_SV
`define RDMA_SUBSYSTEM_SEQ_P099_SV

class seq_p099 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p099)

  function new(string name = "seq_p099");
    super.new(name);
    set_case_id("P099");
  endfunction
endclass

`endif
