`ifndef RDMA_SUBSYSTEM_SEQ_P089_SV
`define RDMA_SUBSYSTEM_SEQ_P089_SV

class seq_p089 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p089)

  function new(string name = "seq_p089");
    super.new(name);
    set_case_id("P089");
  endfunction
endclass

`endif
