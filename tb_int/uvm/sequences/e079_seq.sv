`ifndef RDMA_SUBSYSTEM_SEQ_E079_SV
`define RDMA_SUBSYSTEM_SEQ_E079_SV

class seq_e079 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e079)

  function new(string name = "seq_e079");
    super.new(name);
    set_case_id("E079");
  endfunction
endclass

`endif
