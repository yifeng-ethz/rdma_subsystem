`ifndef RDMA_SUBSYSTEM_SEQ_X068_SV
`define RDMA_SUBSYSTEM_SEQ_X068_SV

class seq_x068 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x068)

  function new(string name = "seq_x068");
    super.new(name);
    set_case_id("X068");
  endfunction
endclass

`endif
