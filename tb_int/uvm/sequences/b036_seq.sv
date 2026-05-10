`ifndef RDMA_SUBSYSTEM_SEQ_B036_SV
`define RDMA_SUBSYSTEM_SEQ_B036_SV

class seq_b036 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b036)

  function new(string name = "seq_b036");
    super.new(name);
    set_case_id("B036");
  endfunction
endclass

`endif
