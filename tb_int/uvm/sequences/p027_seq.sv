`ifndef RDMA_SUBSYSTEM_SEQ_P027_SV
`define RDMA_SUBSYSTEM_SEQ_P027_SV

class seq_p027 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p027)

  function new(string name = "seq_p027");
    super.new(name);
    set_case_id("P027");
  endfunction
endclass

`endif
