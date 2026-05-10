`ifndef RDMA_SUBSYSTEM_SEQ_P019_SV
`define RDMA_SUBSYSTEM_SEQ_P019_SV

class seq_p019 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p019)

  function new(string name = "seq_p019");
    super.new(name);
    set_case_id("P019");
  endfunction
endclass

`endif
