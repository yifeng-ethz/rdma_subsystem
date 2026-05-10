`ifndef RDMA_SUBSYSTEM_SEQ_B090_SV
`define RDMA_SUBSYSTEM_SEQ_B090_SV

class seq_b090 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b090)

  function new(string name = "seq_b090");
    super.new(name);
    set_case_id("B090");
  endfunction
endclass

`endif
