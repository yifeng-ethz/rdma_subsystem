`ifndef RDMA_SUBSYSTEM_SEQ_P057_SV
`define RDMA_SUBSYSTEM_SEQ_P057_SV

class seq_p057 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p057)

  function new(string name = "seq_p057");
    super.new(name);
    set_case_id("P057");
  endfunction
endclass

`endif
