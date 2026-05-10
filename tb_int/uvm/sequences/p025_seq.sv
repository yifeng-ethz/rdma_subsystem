`ifndef RDMA_SUBSYSTEM_SEQ_P025_SV
`define RDMA_SUBSYSTEM_SEQ_P025_SV

class seq_p025 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p025)

  function new(string name = "seq_p025");
    super.new(name);
    set_case_id("P025");
  endfunction
endclass

`endif
