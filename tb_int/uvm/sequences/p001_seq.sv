`ifndef RDMA_SUBSYSTEM_SEQ_P001_SV
`define RDMA_SUBSYSTEM_SEQ_P001_SV

class seq_p001 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p001)

  function new(string name = "seq_p001");
    super.new(name);
    set_case_id("P001");
  endfunction
endclass

`endif
