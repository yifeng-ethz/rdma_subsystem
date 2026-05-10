`ifndef RDMA_SUBSYSTEM_SEQ_P037_SV
`define RDMA_SUBSYSTEM_SEQ_P037_SV

class seq_p037 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p037)

  function new(string name = "seq_p037");
    super.new(name);
    set_case_id("P037");
  endfunction
endclass

`endif
