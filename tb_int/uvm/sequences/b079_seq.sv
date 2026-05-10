`ifndef RDMA_SUBSYSTEM_SEQ_B079_SV
`define RDMA_SUBSYSTEM_SEQ_B079_SV

class seq_b079 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b079)

  function new(string name = "seq_b079");
    super.new(name);
    set_case_id("B079");
  endfunction
endclass

`endif
