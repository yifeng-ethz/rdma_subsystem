`ifndef RDMA_SUBSYSTEM_SEQ_P050_SV
`define RDMA_SUBSYSTEM_SEQ_P050_SV

class seq_p050 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p050)

  function new(string name = "seq_p050");
    super.new(name);
    set_case_id("P050");
  endfunction
endclass

`endif
