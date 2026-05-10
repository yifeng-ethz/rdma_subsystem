`ifndef RDMA_SUBSYSTEM_SEQ_X039_SV
`define RDMA_SUBSYSTEM_SEQ_X039_SV

class seq_x039 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x039)

  function new(string name = "seq_x039");
    super.new(name);
    set_case_id("X039");
  endfunction
endclass

`endif
