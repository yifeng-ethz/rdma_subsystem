`ifndef RDMA_SUBSYSTEM_SEQ_X075_SV
`define RDMA_SUBSYSTEM_SEQ_X075_SV

class seq_x075 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x075)

  function new(string name = "seq_x075");
    super.new(name);
    set_case_id("X075");
  endfunction
endclass

`endif
