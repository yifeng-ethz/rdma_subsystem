`ifndef RDMA_SUBSYSTEM_SEQ_X034_SV
`define RDMA_SUBSYSTEM_SEQ_X034_SV

class seq_x034 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x034)

  function new(string name = "seq_x034");
    super.new(name);
    set_case_id("X034");
  endfunction
endclass

`endif
