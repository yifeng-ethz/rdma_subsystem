`ifndef RDMA_SUBSYSTEM_SEQ_B062_SV
`define RDMA_SUBSYSTEM_SEQ_B062_SV

class seq_b062 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b062)

  function new(string name = "seq_b062");
    super.new(name);
    set_case_id("B062");
  endfunction
endclass

`endif
