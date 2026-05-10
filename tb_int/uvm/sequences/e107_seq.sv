`ifndef RDMA_SUBSYSTEM_SEQ_E107_SV
`define RDMA_SUBSYSTEM_SEQ_E107_SV

class seq_e107 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e107)

  function new(string name = "seq_e107");
    super.new(name);
    set_case_id("E107");
  endfunction
endclass

`endif
