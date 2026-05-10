`ifndef RDMA_SUBSYSTEM_SEQ_E028_SV
`define RDMA_SUBSYSTEM_SEQ_E028_SV

class seq_e028 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e028)

  function new(string name = "seq_e028");
    super.new(name);
    set_case_id("E028");
  endfunction
endclass

`endif
