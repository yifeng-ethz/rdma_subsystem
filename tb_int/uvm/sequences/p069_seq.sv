`ifndef RDMA_SUBSYSTEM_SEQ_P069_SV
`define RDMA_SUBSYSTEM_SEQ_P069_SV

class seq_p069 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p069)

  function new(string name = "seq_p069");
    super.new(name);
    set_case_id("P069");
  endfunction
endclass

`endif
