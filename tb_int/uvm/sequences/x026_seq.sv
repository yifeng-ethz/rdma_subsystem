`ifndef RDMA_SUBSYSTEM_SEQ_X026_SV
`define RDMA_SUBSYSTEM_SEQ_X026_SV

class seq_x026 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x026)

  function new(string name = "seq_x026");
    super.new(name);
    set_case_id("X026");
  endfunction
endclass

`endif
