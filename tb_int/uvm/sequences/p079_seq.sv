`ifndef RDMA_SUBSYSTEM_SEQ_P079_SV
`define RDMA_SUBSYSTEM_SEQ_P079_SV

class seq_p079 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p079)

  function new(string name = "seq_p079");
    super.new(name);
    set_case_id("P079");
  endfunction
endclass

`endif
