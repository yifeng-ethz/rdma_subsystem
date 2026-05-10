`ifndef RDMA_SUBSYSTEM_SEQ_P056_SV
`define RDMA_SUBSYSTEM_SEQ_P056_SV

class seq_p056 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p056)

  function new(string name = "seq_p056");
    super.new(name);
    set_case_id("P056");
  endfunction
endclass

`endif
