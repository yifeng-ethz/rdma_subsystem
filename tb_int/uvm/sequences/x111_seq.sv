`ifndef RDMA_SUBSYSTEM_SEQ_X111_SV
`define RDMA_SUBSYSTEM_SEQ_X111_SV

class seq_x111 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x111)

  function new(string name = "seq_x111");
    super.new(name);
    set_case_id("X111");
  endfunction
endclass

`endif
