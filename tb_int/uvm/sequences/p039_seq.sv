`ifndef RDMA_SUBSYSTEM_SEQ_P039_SV
`define RDMA_SUBSYSTEM_SEQ_P039_SV

class seq_p039 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p039)

  function new(string name = "seq_p039");
    super.new(name);
    set_case_id("P039");
  endfunction
endclass

`endif
