`ifndef RDMA_SUBSYSTEM_SEQ_E011_SV
`define RDMA_SUBSYSTEM_SEQ_E011_SV

class seq_e011 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e011)

  function new(string name = "seq_e011");
    super.new(name);
    set_case_id("E011");
  endfunction
endclass

`endif
