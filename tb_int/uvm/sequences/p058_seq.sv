`ifndef RDMA_SUBSYSTEM_SEQ_P058_SV
`define RDMA_SUBSYSTEM_SEQ_P058_SV

class seq_p058 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p058)

  function new(string name = "seq_p058");
    super.new(name);
    set_case_id("P058");
  endfunction
endclass

`endif
