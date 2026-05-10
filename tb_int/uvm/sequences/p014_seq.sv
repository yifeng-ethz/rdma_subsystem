`ifndef RDMA_SUBSYSTEM_SEQ_P014_SV
`define RDMA_SUBSYSTEM_SEQ_P014_SV

class seq_p014 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p014)

  function new(string name = "seq_p014");
    super.new(name);
    set_case_id("P014");
  endfunction
endclass

`endif
