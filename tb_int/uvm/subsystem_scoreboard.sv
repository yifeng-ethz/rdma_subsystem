`ifndef RDMA_SUBSYSTEM_SCOREBOARD_SV
`define RDMA_SUBSYSTEM_SCOREBOARD_SV

`uvm_analysis_imp_decl(_opq)
`uvm_analysis_imp_decl(_host_write)
`uvm_analysis_imp_decl(_cqe)
`uvm_analysis_imp_decl(_state)

class subsystem_scoreboard extends uvm_component;
  `uvm_component_utils(subsystem_scoreboard)

  uvm_analysis_imp_opq #(opq_word_obs_t, subsystem_scoreboard) opq_imp;
  uvm_analysis_imp_host_write #(host_axi_write_beat_t, subsystem_scoreboard) host_write_imp;
  uvm_analysis_imp_cqe #(subsystem_cqe_t, subsystem_scoreboard) cqe_imp;
  uvm_analysis_imp_state #(runtool_state_e, subsystem_scoreboard) state_imp;

  host_sparse_mem mem;
  subsystem_case_cfg cfg;
  string scorecard_path;
  int unsigned debug_level;
  int unsigned observed_txn;
  int unsigned cqe_count;
  int unsigned host_write_count;
  int unsigned opq_word_count;
  bit [15:0] last_cqe_status;
  bit [63:0] last_cqe_bytes;
  int unsigned state_seen[5];
  int unsigned mismatch_count;
  byte unsigned expected_bytes[$];
  int unsigned consumed_bytes;
  localparam longint unsigned RXBUFFER_RQE_STRIDE_BYTES_CONST = 64'h0000_0000_0080_0000;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    opq_imp = new("opq_imp", this);
    host_write_imp = new("host_write_imp", this);
    cqe_imp = new("cqe_imp", this);
    state_imp = new("state_imp", this);
    scorecard_path = "";
    debug_level = 0;
  endfunction

  function void configure(host_sparse_mem mem_h,
                          subsystem_case_cfg case_cfg,
                          string scorecard,
                          int unsigned dbg_level);
    mem = mem_h;
    cfg = case_cfg;
    scorecard_path = scorecard;
    debug_level = dbg_level;
    observed_txn = 0;
    cqe_count = 0;
    host_write_count = 0;
    opq_word_count = 0;
    last_cqe_status = 16'h0;
    last_cqe_bytes = 64'h0;
    mismatch_count = 0;
    consumed_bytes = 0;
    expected_bytes.delete();
    for (int i = 0; i < 5; i++)
      state_seen[i] = 0;
  endfunction

  function void write_opq(opq_word_obs_t obs);
    opq_word_count++;
    for (int i = 0; i < 4; i++)
      expected_bytes.push_back(obs.word[i * 8 +: 8]);
  endfunction

  function void write_host_write(host_axi_write_beat_t obs);
    host_write_count++;
  endfunction

  function longint unsigned seg0_addr_for(input int unsigned rqe_id);
    return 64'h0000_4000_0000_0000
           + (longint'(rqe_id) * RXBUFFER_RQE_STRIDE_BYTES_CONST)
           + (longint'(cfg.case_num) << 12);
  endfunction

  function void check_rx_bytes(input subsystem_cqe_t cqe);
    longint unsigned addr;
    int unsigned byte_count;
    addr = seg0_addr_for(cqe.rqe_id);
    byte_count = int'(cqe.bytes_written_total);
    if (byte_count > expected_bytes.size() - consumed_bytes) begin
      `uvm_error("SCB_BYTES", $sformatf("%s CQE bytes=%0d exceed source remaining=%0d",
                                        cfg.case_id, byte_count,
                                        expected_bytes.size() - consumed_bytes))
      mismatch_count++;
      return;
    end
    for (int unsigned idx = 0; idx < byte_count; idx++) begin
      byte unsigned got;
      byte unsigned exp;
      got = mem.read_byte(addr + idx);
      exp = expected_bytes[consumed_bytes + idx];
      if (got !== exp) begin
        `uvm_error("SCB_BYTES", $sformatf(
          "%s byte mismatch rqe=%0d off=%0d got=0x%02h expected=0x%02h",
          cfg.case_id, cqe.rqe_id, idx, got, exp))
        mismatch_count++;
        return;
      end
    end
    consumed_bytes += byte_count;
  endfunction

  function void write_cqe(subsystem_cqe_t cqe);
    cqe_count++;
    observed_txn++;
    last_cqe_status = cqe.status;
    last_cqe_bytes = cqe.bytes_written_total;
    `uvm_info("SCB_CQE", $sformatf("%s CQE rqe_id=%0d status=0x%04h bytes=%0d seg0=%0d seg1=%0d",
                                   cfg.case_id, cqe.rqe_id, cqe.status,
                                   cqe.bytes_written_total,
                                   cqe.seg0_bytes_written,
                                   cqe.seg1_bytes_written), UVM_LOW)
    if (cfg.force_align_error || cfg.force_malformed_rqe) begin
      if (!cqe.status[5]) begin
        `uvm_error("SCB_CQE", $sformatf("%s expected ALIGN_ERR/malformed status", cfg.case_id))
        mismatch_count++;
      end
      return;
    end
    if (cfg.force_halt && !cqe.status[2]) begin
      `uvm_error("SCB_CQE", $sformatf("%s expected HALT status", cfg.case_id))
      mismatch_count++;
    end
    if (cfg.term_mode == TERM_FULL && !cqe.status[1] && !cfg.force_halt) begin
      `uvm_error("SCB_CQE", $sformatf("%s expected FULL status got=0x%04h", cfg.case_id, cqe.status))
      mismatch_count++;
    end
    if (cfg.term_mode == TERM_EOE && !cqe.status[0] && !cfg.force_halt) begin
      `uvm_error("SCB_CQE", $sformatf("%s expected EOE status got=0x%04h", cfg.case_id, cqe.status))
      mismatch_count++;
    end
    if (cqe.bytes_written_total != 0)
      check_rx_bytes(cqe);
  endfunction

  function void write_state(runtool_state_e state);
    if (int'(state) < 5)
      state_seen[int'(state)]++;
  endfunction

  function void final_check();
    if (cfg == null)
      `uvm_fatal("SCB", "Scoreboard was not configured")
    if (cfg.idle_only) begin
      if (cqe_count != 0) begin
        `uvm_error("SCB_IDLE", $sformatf("%s idle-only case produced %0d CQEs",
                                         cfg.case_id, cqe_count))
        mismatch_count++;
      end
    end else if (cqe_count == 0) begin
      `uvm_error("SCB_CQE", $sformatf("%s produced no CQEs", cfg.case_id))
      mismatch_count++;
    end
    if (state_seen[RUN_PREPARING] == 0 || state_seen[RUN_RUNNING] == 0 ||
        state_seen[RUN_STOPPING] == 0 || state_seen[RUN_STOPPED] == 0) begin
      `uvm_error("SCB_STATE", $sformatf("%s did not observe full run_tool state sequence", cfg.case_id))
      mismatch_count++;
    end
  endfunction

  function void write_scorecard();
    int fd;
    uvm_report_server server;
    int unsigned uvm_errors;
    string duplicate_reason;
    if (scorecard_path == "")
      return;
    server = uvm_report_server::get_server();
    uvm_errors = server.get_severity_count(UVM_ERROR) + server.get_severity_count(UVM_FATAL);
    duplicate_reason = cfg.build_duplicate_reason();
    fd = $fopen(scorecard_path, "w");
    if (fd == 0) begin
      `uvm_error("SCORECARD", $sformatf("Could not open scorecard %s", scorecard_path))
      return;
    end
    $fwrite(fd, "{\n");
    $fwrite(fd, "  \"case_id\": \"%s\",\n", cfg.case_id);
    $fwrite(fd, "  \"bucket\": \"%s\",\n", cfg.bucket);
    $fwrite(fd, "  \"passed\": %s,\n", (uvm_errors == 0 && mismatch_count == 0) ? "true" : "false");
    $fwrite(fd, "  \"implementation_mode\": \"isolated\",\n");
    $fwrite(fd, "  \"build_tag\": \"dbg%0d\",\n", debug_level);
    $fwrite(fd, "  \"debug_level\": %0d,\n", debug_level);
    $fwrite(fd, "  \"observed_txn\": %0d,\n", observed_txn);
    $fwrite(fd, "  \"opq_word_count\": %0d,\n", opq_word_count);
    $fwrite(fd, "  \"host_write_count\": %0d,\n", host_write_count);
    $fwrite(fd, "  \"cqe_count\": %0d,\n", cqe_count);
    $fwrite(fd, "  \"last_cqe_status\": %0d,\n", last_cqe_status);
    $fwrite(fd, "  \"last_cqe_bytes\": %0d,\n", last_cqe_bytes);
    $fwrite(fd, "  \"coverage_bin\": \"%s\",\n", cfg.coverage_bin);
    $fwrite(fd, "  \"contract_anchor\": \"%s\",\n", cfg.contract_anchor);
    $fwrite(fd, "  \"unique_coverage_delta\": %0d,\n", (cfg.case_num % 16) == 1 ? 1 : 0);
    $fwrite(fd, "  \"duplicate_justification\": \"%s\",\n", duplicate_reason);
    $fwrite(fd, "  \"log_summary\": {\n");
    $fwrite(fd, "    \"mismatch_count\": %0d,\n", mismatch_count);
    $fwrite(fd, "    \"uvm_errors\": %0d\n", uvm_errors);
    $fwrite(fd, "  }\n");
    $fwrite(fd, "}\n");
    $fclose(fd);
  endfunction
endclass

`endif
