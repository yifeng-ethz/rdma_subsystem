`ifndef RDMA_SUBSYSTEM_SEQ_X089_SV
`define RDMA_SUBSYSTEM_SEQ_X089_SV

class seq_x089 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x089)

  function new(string name = "seq_x089");
    super.new(name);
    set_case_id("X089");
  endfunction
endclass

`endif
