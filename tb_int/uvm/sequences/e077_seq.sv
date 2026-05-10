`ifndef RDMA_SUBSYSTEM_SEQ_E077_SV
`define RDMA_SUBSYSTEM_SEQ_E077_SV

class seq_e077 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e077)

  function new(string name = "seq_e077");
    super.new(name);
    set_case_id("E077");
  endfunction
endclass

`endif
