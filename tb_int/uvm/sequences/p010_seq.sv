`ifndef RDMA_SUBSYSTEM_SEQ_P010_SV
`define RDMA_SUBSYSTEM_SEQ_P010_SV

class seq_p010 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p010)

  function new(string name = "seq_p010");
    super.new(name);
    set_case_id("P010");
  endfunction
endclass

`endif
