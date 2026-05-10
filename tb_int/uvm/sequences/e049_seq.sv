`ifndef RDMA_SUBSYSTEM_SEQ_E049_SV
`define RDMA_SUBSYSTEM_SEQ_E049_SV

class seq_e049 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e049)

  function new(string name = "seq_e049");
    super.new(name);
    set_case_id("E049");
  endfunction
endclass

`endif
