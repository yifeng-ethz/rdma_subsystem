`ifndef RDMA_SUBSYSTEM_SEQ_X069_SV
`define RDMA_SUBSYSTEM_SEQ_X069_SV

class seq_x069 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x069)

  function new(string name = "seq_x069");
    super.new(name);
    set_case_id("X069");
  endfunction
endclass

`endif
