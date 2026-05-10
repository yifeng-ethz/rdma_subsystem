`ifndef RDMA_SUBSYSTEM_SEQ_X121_SV
`define RDMA_SUBSYSTEM_SEQ_X121_SV

class seq_x121 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x121)

  function new(string name = "seq_x121");
    super.new(name);
    set_case_id("X121");
  endfunction
endclass

`endif
