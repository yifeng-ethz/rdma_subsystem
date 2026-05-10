`ifndef RDMA_SUBSYSTEM_SEQ_X049_SV
`define RDMA_SUBSYSTEM_SEQ_X049_SV

class seq_x049 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x049)

  function new(string name = "seq_x049");
    super.new(name);
    set_case_id("X049");
  endfunction
endclass

`endif
