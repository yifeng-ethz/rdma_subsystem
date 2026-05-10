`ifndef RDMA_SUBSYSTEM_SEQ_X019_SV
`define RDMA_SUBSYSTEM_SEQ_X019_SV

class seq_x019 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x019)

  function new(string name = "seq_x019");
    super.new(name);
    set_case_id("X019");
  endfunction
endclass

`endif
