`ifndef RDMA_SUBSYSTEM_SEQ_P127_SV
`define RDMA_SUBSYSTEM_SEQ_P127_SV

class seq_p127 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p127)

  function new(string name = "seq_p127");
    super.new(name);
    set_case_id("P127");
  endfunction
endclass

`endif
