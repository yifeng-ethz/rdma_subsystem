`ifndef RDMA_SUBSYSTEM_SEQ_P034_SV
`define RDMA_SUBSYSTEM_SEQ_P034_SV

class seq_p034 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p034)

  function new(string name = "seq_p034");
    super.new(name);
    set_case_id("P034");
  endfunction
endclass

`endif
