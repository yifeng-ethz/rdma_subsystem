`ifndef RDMA_SUBSYSTEM_SEQ_E069_SV
`define RDMA_SUBSYSTEM_SEQ_E069_SV

class seq_e069 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e069)

  function new(string name = "seq_e069");
    super.new(name);
    set_case_id("E069");
  endfunction
endclass

`endif
