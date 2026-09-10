extends SceneTree
# 端到端 headless 验证 v2：同一进程内实例化【两个真实 Main.tscn】，
# A=主机(127.0.0.1:8910)、B=加入方；走完整握手后由 A 权威模拟并发快照，
# B 走真实客户端路径（_receive_snapshot_payload/_apply_remote_snapshot/A4插值）。
# 通过注入 B 的输入制造状态变化，最后断言：双方 RTT 可测、快照无丢失、棋盘增量同步一致。
# 运行：godot --headless --path <project> -s res://test/net_e2e2.gd

var host_a: Node = null
var client_b: Node = null
var begin_ms := 0
var connect_scheduled := false
var last_progress_ms := 0
var last_inject_ms := 0
var inject_on := false
var playing_since := 0
var board_equal_hits := 0
var board_check_ms := 0

func _initialize() -> void:
	begin_ms = Time.get_ticks_msec()
	Engine.max_fps = 240
	var packed := load("res://Main.tscn") as PackedScene
	host_a = packed.instantiate()
	root.add_child(host_a)
	host_a.call("_begin_host")
	print("E2E2 hostA listening port=", host_a.get("net_listen_port"))
	client_b = packed.instantiate()
	root.add_child(client_b)
	connect_scheduled = true
	process_frame.connect(_tick)

func _boards_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for y in range(a.size()):
		var ra: Array = a[y]
		var rb: Array = b[y]
		if ra.size() != rb.size():
			return false
		for x in range(ra.size()):
			if int(ra[x]) != int(rb[x]):
				return false
	return true

func _tick() -> void:
	var now := Time.get_ticks_msec()
	if now - begin_ms > 16000:
		print("E2E2 TIMEOUT hostPhase=", host_a.get("phase"), " clientPhase=", client_b.get("phase"),
			" applied=", client_b.get("_last_applied_snap_seq"), " sent=", host_a.get("_snap_sent_count"))
		_cleanup(2)
		return

	# 让加入方在主机起监听后 ~300ms 再发起连接
	if connect_scheduled and now - begin_ms > 300:
		connect_scheduled = false
		client_b.set("ip_buffer", "127.0.0.1")
		client_b.call("_begin_join_connect")
		print("E2E2 clientB connecting ...")

	var client_phase: String = client_b.get("phase")
	if client_phase == "playing":
		if playing_since == 0:
			playing_since = now
			print("E2E2 clientB is PLAYING (received snapshots)")
		# 注入 P2 输入：交替左移/跳跃点按（模拟真实客户端上行）
		if now - last_inject_ms > 350:
			last_inject_ms = now
			inject_on = not inject_on
			client_b.call("_poll_local_inputs")
			var frame: Dictionary = client_b.get("_input_frame")
			frame["p2_left"] = inject_on
			if inject_on:
				frame["p2_jump"] = true
			client_b.set("_input_frame", frame)
			client_b.call("_send_local_input_if_playing", 0.016)

		if now - last_progress_ms > 700:
			last_progress_ms = now
			print("E2E2 progress sent=", host_a.get("_snap_sent_count"),
				" applied=", client_b.get("_last_applied_snap_seq"),
				" hostRTT=", host_a.get("_rtt_est_ms"), " clientRTT=", client_b.get("_rtt_est_ms"),
				" visFrom=", client_b.get("_vis_has_from"))

		# 棋盘一致性抽样（等上 1.5s 后开始）
		if now - playing_since > 1500 and now - board_check_ms > 400:
			board_check_ms = now
			if _boards_equal(host_a.get("board"), client_b.get("board")):
				board_equal_hits += 1

		if now - playing_since >= 4500:
			var sent: int = host_a.get("_snap_sent_count")
			var applied: int = client_b.get("_last_applied_snap_seq")
			var h_rtt: float = host_a.get("_rtt_est_ms")
			var c_rtt: float = client_b.get("_rtt_est_ms")
			var fails: Array = []
			if h_rtt < 0.0:
				fails.append("host RTT not measured")
			if c_rtt < 0.0:
				fails.append("client RTT not measured")
			if sent < applied or sent - applied > 1:
				fails.append("snapshot loss: sent=%d applied=%d" % [sent, applied])
			if board_equal_hits < 1:
				fails.append("client board never matched host")
			if not bool(client_b.get("_vis_has_from")):
				fails.append("client visual target never initialized")
			if fails.is_empty():
				print("E2E2 OK: sent=", sent, " applied=", applied,
					" hostRTT=", h_rtt, " clientRTT=", c_rtt,
					" boardEqualSamples=", board_equal_hits)
				_cleanup(0)
			else:
				print("E2E2 FAIL: ", ", ".join(fails))
				_cleanup(5)

func _cleanup(code: int) -> void:
	if host_a != null:
		host_a.call("_close_net")
		root.remove_child(host_a)
		host_a.queue_free()
		host_a = null
	if client_b != null:
		client_b.call("_close_net")
		root.remove_child(client_b)
		client_b.queue_free()
		client_b = null
	if code == 0:
		quit(0)
	else:
		quit(code)
