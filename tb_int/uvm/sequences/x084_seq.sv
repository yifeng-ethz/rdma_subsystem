`ifndef RDMA_SUBSYSTEM_SEQ_X084_SV
`define RDMA_SUBSYSTEM_SEQ_X084_SV

class seq_x084 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x084)

  function new(string name = "seq_x084");
    super.new(name);
    set_case_id("X084");
  endfunction
endclass

`endif
