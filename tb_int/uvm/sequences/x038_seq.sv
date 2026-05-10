`ifndef RDMA_SUBSYSTEM_SEQ_X038_SV
`define RDMA_SUBSYSTEM_SEQ_X038_SV

class seq_x038 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x038)

  function new(string name = "seq_x038");
    super.new(name);
    set_case_id("X038");
  endfunction
endclass

`endif
