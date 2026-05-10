`ifndef RDMA_SUBSYSTEM_SEQ_E061_SV
`define RDMA_SUBSYSTEM_SEQ_E061_SV

class seq_e061 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e061)

  function new(string name = "seq_e061");
    super.new(name);
    set_case_id("E061");
  endfunction
endclass

`endif
