`ifndef RDMA_SUBSYSTEM_SEQ_B049_SV
`define RDMA_SUBSYSTEM_SEQ_B049_SV

class seq_b049 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b049)

  function new(string name = "seq_b049");
    super.new(name);
    set_case_id("B049");
  endfunction
endclass

`endif
