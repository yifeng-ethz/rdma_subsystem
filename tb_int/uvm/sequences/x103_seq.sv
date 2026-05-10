`ifndef RDMA_SUBSYSTEM_SEQ_X103_SV
`define RDMA_SUBSYSTEM_SEQ_X103_SV

class seq_x103 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x103)

  function new(string name = "seq_x103");
    super.new(name);
    set_case_id("X103");
  endfunction
endclass

`endif
