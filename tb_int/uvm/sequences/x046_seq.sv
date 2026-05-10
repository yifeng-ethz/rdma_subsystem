`ifndef RDMA_SUBSYSTEM_SEQ_X046_SV
`define RDMA_SUBSYSTEM_SEQ_X046_SV

class seq_x046 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x046)

  function new(string name = "seq_x046");
    super.new(name);
    set_case_id("X046");
  endfunction
endclass

`endif
