`ifndef RDMA_SUBSYSTEM_SEQ_X115_SV
`define RDMA_SUBSYSTEM_SEQ_X115_SV

class seq_x115 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x115)

  function new(string name = "seq_x115");
    super.new(name);
    set_case_id("X115");
  endfunction
endclass

`endif
