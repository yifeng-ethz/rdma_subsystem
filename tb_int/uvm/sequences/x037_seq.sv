`ifndef RDMA_SUBSYSTEM_SEQ_X037_SV
`define RDMA_SUBSYSTEM_SEQ_X037_SV

class seq_x037 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x037)

  function new(string name = "seq_x037");
    super.new(name);
    set_case_id("X037");
  endfunction
endclass

`endif
