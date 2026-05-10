`ifndef RDMA_SUBSYSTEM_SEQ_X122_SV
`define RDMA_SUBSYSTEM_SEQ_X122_SV

class seq_x122 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x122)

  function new(string name = "seq_x122");
    super.new(name);
    set_case_id("X122");
  endfunction
endclass

`endif
