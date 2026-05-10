`ifndef RDMA_SUBSYSTEM_SEQ_X011_SV
`define RDMA_SUBSYSTEM_SEQ_X011_SV

class seq_x011 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x011)

  function new(string name = "seq_x011");
    super.new(name);
    set_case_id("X011");
  endfunction
endclass

`endif
