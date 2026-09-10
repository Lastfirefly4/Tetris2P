extends SceneTree
# P2 上行输入回归：主机 A + 加入方 B（真实 Main.tscn 双实例）。
# 关键点：B 通过【真实 Input 单例按键】(Input.action_press) 驱动，走完整链路
#   B: Input.is_action_pressed → _poll_local_inputs → _send_local_input_if_playing → MSG_INPUT
#   A: MSG_INPUT → _apply_remote_input_bitset → _remote_p2_bits → _input_frame → _handle_player_inputs
# 断言：A（权威方）角色真的移动/跳跃，且 B 的镜像位置跟随。
# 运行：godot --headless --path <project> -s res://test/net_input_test.gd

var host_a: Node = null
var client_b: Node = null
var begin_ms := 0
var connect_scheduled := false
var phase := "wait_start"
var step_ms := 0
var x_before := 0
var y_before := 0
var jump_done := false
var fails: Array = []

func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fails.append(label)

func _initialize() -> void:
	begin_ms = Time.get_ticks_msec()
	Engine.max_fps = 240
	var packed := load("res://Main.tscn") as PackedScene
	host_a = packed.instantiate()
	root.add_child(host_a)
	host_a.call("_begin_host")
	client_b = packed.instantiate()
	root.add_child(client_b)
	connect_scheduled = true
	process_frame.connect(_tick)

func _tick() -> void:
	var now := Time.get_ticks_msec()
	if now - begin_ms > 20000:
		print("INPUT TEST TIMEOUT hostPhase=", host_a.get("phase"), " clientPhase=", client_b.get("phase"),
			" lastSentBits=", client_b.get("_last_sent_input_bits"), " remoteBits=", host_a.get("_remote_p2_bits"))
		_cleanup(2)
		return

	if connect_scheduled and now - begin_ms > 300:
		connect_scheduled = false
		client_b.set("ip_buffer", "127.0.0.1")
		client_b.call("_begin_join_connect")

	var a_phase: String = host_a.get("phase")
	var b_phase: String = client_b.get("phase")
	if a_phase != "playing" or b_phase != "playing":
		return
	# 冻结方块重力：让测试期间棋盘与角色状态可预测
	host_a.set("gravity_accumulator", -1000000.0)

	if phase == "wait_start":
		phase = "settle"
		step_ms = now
		print("both PLAYING; settle 800ms  clientLocalControl=", client_b.get("local_control"),
			" hostLocalControl=", host_a.get("local_control"))
		return

	if phase == "settle":
		if now - step_ms < 800:
			return
		x_before = int(host_a.get("man_x"))
		y_before = int(host_a.get("man_y"))
		print("baseline host man_x=", x_before, " man_y=", y_before)
		Input.action_press("p2_left")
		phase = "move_left"
		step_ms = now
		return

	if phase == "move_left":
		if now - step_ms < 900:
			return
		Input.action_release("p2_left")
		print("diag: client lastSentBits=", client_b.get("_last_sent_input_bits"),
			" host remoteBits=", host_a.get("_remote_p2_bits"),
			" host frame p2_left=", (host_a.get("_input_frame") as Dictionary).get("p2_left", "?"),
			" client frame p2_left=", (client_b.get("_input_frame") as Dictionary).get("p2_left", "?"))
		var x_after := int(host_a.get("man_x"))
		_check(x_after < x_before, "P2 held LEFT moves authoritative man (x %d -> %d)" % [x_before, x_after])
		_check(int(client_b.get("man_x")) == int(host_a.get("man_x")), "client mirrored man_x follows host")
		x_before = int(host_a.get("man_x"))
		phase = "jump"
		step_ms = now
		Input.action_press("p2_jump")
		return

	if phase == "jump":
		if now - step_ms < 120:
			return
		Input.action_release("p2_jump")
		var vel := float(host_a.get("man_velocity_y"))
		var jc := int(host_a.get("man_jump_count"))
		print("jump diag: host man_velocity_y=", vel, " man_jump_count=", jc,
			" man_y=", host_a.get("man_y"), " (was ", y_before, ")")
		_check(jc >= 1 or vel < 0.0, "P2 jump reaches authoritative sim (jump_count=%d vel=%.1f)" % [jc, vel])
		jump_done = true
		phase = "follow"
		step_ms = now
		return

	if phase == "follow":
		if now - step_ms < 600:
			return
		print("follow diag: host man_x=", host_a.get("man_x"), " client man_x=", client_b.get("man_x"),
			" client vis_man_x=", client_b.get("_vis_man_x"))
		_check(absf(float(host_a.get("man_x")) - float(client_b.get("man_x"))) <= 0.6, "client mirror matches host man_x")
		_check(bool(host_a.get("man_alive")), "man still alive before tap tests")
		# —— 按住 RIGHT 把角色移到中间，为“极短点按”测试留出空间 ——
		Input.action_press("p2_right")
		phase = "move_right"
		step_ms = now
		return

	if phase == "move_right":
		if now - step_ms < 700:
			return
		Input.action_release("p2_right")
		x_before = int(host_a.get("man_x"))
		print("tap diag: pre-tap host man_x=", x_before)
		# 模拟“两帧之间瞬间按一下 A 就松开”（逐帧轮询会整帧丢弃，靠事件锁存补回）
		var down := InputEventKey.new()
		down.keycode = KEY_A
		down.physical_keycode = KEY_A
		down.pressed = true
		client_b.call("_input", down)
		var up := InputEventKey.new()
		up.keycode = KEY_A
		up.physical_keycode = KEY_A
		up.pressed = false
		client_b.call("_input", up)
		phase = "tap_wait"
		step_ms = now
		return

	if phase == "tap_wait":
		if now - step_ms < 400:
			return
		var x_after := int(host_a.get("man_x"))
		_check(x_after == x_before - 1, "ultra-short tap is not lost (man_x %d -> %d)" % [x_before, x_after])
		# —— 方向键备选键位：真实按键事件应当被客户端采集为 P2 输入 ——
		var left_down := InputEventKey.new()
		left_down.keycode = KEY_LEFT
		left_down.physical_keycode = KEY_LEFT
		left_down.pressed = true
		Input.parse_input_event(left_down)
		phase = "arrow"
		step_ms = now
		return

	if phase == "arrow":
		if now - step_ms < 700:
			return
		var polled: bool = bool((client_b.get("_input_frame") as Dictionary).get("p2_left", false))
		_check(polled, "arrow key is polled as P2 left on client")
		var left_up := InputEventKey.new()
		left_up.keycode = KEY_LEFT
		left_up.physical_keycode = KEY_LEFT
		left_up.pressed = false
		Input.parse_input_event(left_up)
		var x_arrow := int(host_a.get("man_x"))
		_check(x_arrow < x_before - 1, "arrow key moved authoritative man (x=%d, was %d)" % [x_arrow, x_before])
		# —— 回归：对局中“连接超时”绝不能触发（触发会把 net_state 打成 failed，
		# 加入方的输入/心跳全部静默停摆，而快照仍在单向推送）——
		client_b.set("net_join_timeout_ms", 1)
		client_b.set("_net_join_timeout_ms", maxi(1, now - 2000))
		phase = "guard_wait"
		step_ms = now
		return

	if phase == "guard_wait":
		if now - step_ms < 500:
			return
		_check(client_b.get("net_state") == "connected", "client stays connected past join-timeout window")
		_check(client_b.get("phase") == "playing", "client still playing during guard window")
		x_before = int(host_a.get("man_x"))
		Input.action_press("p2_right")
		phase = "guard_move"
		step_ms = now
		return

	if phase == "guard_move":
		if now - step_ms < 600:
			return
		Input.action_release("p2_right")
		var x2 := int(host_a.get("man_x"))
		_check(x2 > x_before, "input still uplinked after join-timeout window (x %d -> %d)" % [x_before, x2])
		_cleanup(0 if fails.is_empty() else 5)

func _cleanup(code: int) -> void:
	Input.action_release("p2_left")
	Input.action_release("p2_jump")
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
	print("INPUT TEST ", "OK" if fails.is_empty() else ("FAILED x%d" % fails.size()))
	quit(code)
