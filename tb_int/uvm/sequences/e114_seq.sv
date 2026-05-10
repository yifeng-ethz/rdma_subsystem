`ifndef RDMA_SUBSYSTEM_SEQ_E114_SV
`define RDMA_SUBSYSTEM_SEQ_E114_SV

class seq_e114 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e114)

  function new(string name = "seq_e114");
    super.new(name);
    set_case_id("E114");
  endfunction
endclass

`endif
