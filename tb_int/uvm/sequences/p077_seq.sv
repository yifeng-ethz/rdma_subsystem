`ifndef RDMA_SUBSYSTEM_SEQ_P077_SV
`define RDMA_SUBSYSTEM_SEQ_P077_SV

class seq_p077 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p077)

  function new(string name = "seq_p077");
    super.new(name);
    set_case_id("P077");
  endfunction
endclass

`endif
