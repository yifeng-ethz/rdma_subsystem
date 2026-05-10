`ifndef RDMA_SUBSYSTEM_SEQ_P007_SV
`define RDMA_SUBSYSTEM_SEQ_P007_SV

class seq_p007 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p007)

  function new(string name = "seq_p007");
    super.new(name);
    set_case_id("P007");
  endfunction
endclass

`endif
