`ifndef RDMA_SUBSYSTEM_SEQ_B045_SV
`define RDMA_SUBSYSTEM_SEQ_B045_SV

class seq_b045 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b045)

  function new(string name = "seq_b045");
    super.new(name);
    set_case_id("B045");
  endfunction
endclass

`endif
