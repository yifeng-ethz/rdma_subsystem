`ifndef RDMA_SUBSYSTEM_SEQ_B019_SV
`define RDMA_SUBSYSTEM_SEQ_B019_SV

class seq_b019 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b019)

  function new(string name = "seq_b019");
    super.new(name);
    set_case_id("B019");
  endfunction
endclass

`endif
