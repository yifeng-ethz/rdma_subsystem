`ifndef RDMA_SUBSYSTEM_SEQ_E051_SV
`define RDMA_SUBSYSTEM_SEQ_E051_SV

class seq_e051 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e051)

  function new(string name = "seq_e051");
    super.new(name);
    set_case_id("E051");
  endfunction
endclass

`endif
