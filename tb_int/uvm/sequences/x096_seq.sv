`ifndef RDMA_SUBSYSTEM_SEQ_X096_SV
`define RDMA_SUBSYSTEM_SEQ_X096_SV

class seq_x096 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x096)

  function new(string name = "seq_x096");
    super.new(name);
    set_case_id("X096");
  endfunction
endclass

`endif
