`ifndef RDMA_SUBSYSTEM_SEQ_P090_SV
`define RDMA_SUBSYSTEM_SEQ_P090_SV

class seq_p090 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p090)

  function new(string name = "seq_p090");
    super.new(name);
    set_case_id("P090");
  endfunction
endclass

`endif
