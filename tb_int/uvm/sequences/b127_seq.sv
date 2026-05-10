`ifndef RDMA_SUBSYSTEM_SEQ_B127_SV
`define RDMA_SUBSYSTEM_SEQ_B127_SV

class seq_b127 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b127)

  function new(string name = "seq_b127");
    super.new(name);
    set_case_id("B127");
  endfunction
endclass

`endif
