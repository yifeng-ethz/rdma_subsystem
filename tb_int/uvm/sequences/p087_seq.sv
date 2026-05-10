`ifndef RDMA_SUBSYSTEM_SEQ_P087_SV
`define RDMA_SUBSYSTEM_SEQ_P087_SV

class seq_p087 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p087)

  function new(string name = "seq_p087");
    super.new(name);
    set_case_id("P087");
  endfunction
endclass

`endif
