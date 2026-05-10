`ifndef RDMA_SUBSYSTEM_SEQ_P065_SV
`define RDMA_SUBSYSTEM_SEQ_P065_SV

class seq_p065 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p065)

  function new(string name = "seq_p065");
    super.new(name);
    set_case_id("P065");
  endfunction
endclass

`endif
