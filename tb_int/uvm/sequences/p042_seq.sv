`ifndef RDMA_SUBSYSTEM_SEQ_P042_SV
`define RDMA_SUBSYSTEM_SEQ_P042_SV

class seq_p042 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p042)

  function new(string name = "seq_p042");
    super.new(name);
    set_case_id("P042");
  endfunction
endclass

`endif
