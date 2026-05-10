`ifndef RDMA_SUBSYSTEM_SEQ_P126_SV
`define RDMA_SUBSYSTEM_SEQ_P126_SV

class seq_p126 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p126)

  function new(string name = "seq_p126");
    super.new(name);
    set_case_id("P126");
  endfunction
endclass

`endif
