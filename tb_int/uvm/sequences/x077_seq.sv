`ifndef RDMA_SUBSYSTEM_SEQ_X077_SV
`define RDMA_SUBSYSTEM_SEQ_X077_SV

class seq_x077 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x077)

  function new(string name = "seq_x077");
    super.new(name);
    set_case_id("X077");
  endfunction
endclass

`endif
