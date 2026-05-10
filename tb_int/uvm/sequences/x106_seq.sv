`ifndef RDMA_SUBSYSTEM_SEQ_X106_SV
`define RDMA_SUBSYSTEM_SEQ_X106_SV

class seq_x106 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x106)

  function new(string name = "seq_x106");
    super.new(name);
    set_case_id("X106");
  endfunction
endclass

`endif
