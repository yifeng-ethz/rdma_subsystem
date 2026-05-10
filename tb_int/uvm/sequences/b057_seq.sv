`ifndef RDMA_SUBSYSTEM_SEQ_B057_SV
`define RDMA_SUBSYSTEM_SEQ_B057_SV

class seq_b057 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b057)

  function new(string name = "seq_b057");
    super.new(name);
    set_case_id("B057");
  endfunction
endclass

`endif
