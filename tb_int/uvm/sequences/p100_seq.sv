`ifndef RDMA_SUBSYSTEM_SEQ_P100_SV
`define RDMA_SUBSYSTEM_SEQ_P100_SV

class seq_p100 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p100)

  function new(string name = "seq_p100");
    super.new(name);
    set_case_id("P100");
  endfunction
endclass

`endif
