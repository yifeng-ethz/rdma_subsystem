`ifndef RDMA_SUBSYSTEM_SEQ_P016_SV
`define RDMA_SUBSYSTEM_SEQ_P016_SV

class seq_p016 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p016)

  function new(string name = "seq_p016");
    super.new(name);
    set_case_id("P016");
  endfunction
endclass

`endif
