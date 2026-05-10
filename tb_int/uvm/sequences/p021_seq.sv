`ifndef RDMA_SUBSYSTEM_SEQ_P021_SV
`define RDMA_SUBSYSTEM_SEQ_P021_SV

class seq_p021 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p021)

  function new(string name = "seq_p021");
    super.new(name);
    set_case_id("P021");
  endfunction
endclass

`endif
