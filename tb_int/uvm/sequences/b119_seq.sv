`ifndef RDMA_SUBSYSTEM_SEQ_B119_SV
`define RDMA_SUBSYSTEM_SEQ_B119_SV

class seq_b119 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b119)

  function new(string name = "seq_b119");
    super.new(name);
    set_case_id("B119");
  endfunction
endclass

`endif
