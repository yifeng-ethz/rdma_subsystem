`ifndef RDMA_SUBSYSTEM_SEQ_X064_SV
`define RDMA_SUBSYSTEM_SEQ_X064_SV

class seq_x064 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x064)

  function new(string name = "seq_x064");
    super.new(name);
    set_case_id("X064");
  endfunction
endclass

`endif
