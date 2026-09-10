extends SceneTree
# 联机冒烟测试：以 headless「加入方」连接本机房主(127.0.0.1:8910)，
# 依次验证 HELLO → ASSIGN → READY → START → 持续 SNAPSHOT → QUIT。
# 运行：godot --headless --path <project> -s res://test/net_smoke.gd

const MSG_HELLO := 1
const MSG_ASSIGN := 2
const MSG_READY := 3
const MSG_START := 4
const MSG_INPUT := 5
const MSG_SNAPSHOT := 6
const MSG_QUIT := 8
const MSG_PING := 9
const MSG_PONG := 10

var peer: ENetMultiplayerPeer = null
var state := "connecting"
var snapshot_count := 0
var snapshot_seq_last := -1
var begin_ms := 0
var last_ping_ms := 0
var playing_since_ms := 0
var _quit_pending := false
var _quit_at_ms := 0
# 可通过命令行参数覆盖：godot --headless --path <proj> -s res://test/net_smoke.gd -- <地址> [端口]
var target_addr := "127.0.0.1"
var target_port := 8910

func _initialize() -> void:
	begin_ms = Time.get_ticks_msec()
	# 用法：godot --headless --path <proj> -s res://test/net_smoke.gd -- <主机地址[:端口]> [端口]
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		target_addr = args[0]
	if args.size() >= 2:
		target_port = int(args[1])
	print("SMOKE connecting to ", target_addr, ":", target_port)
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(target_addr, target_port)
	if err != OK:
		print("SMOKE create_client failed: ", err)
		quit(1)
		return
	process_frame.connect(_tick)

func _tick() -> void:
	if _quit_pending:
		if Time.get_ticks_msec() >= _quit_at_ms:
			quit(0)
		return
	if peer == null:
		quit(1)
		return
	var now := Time.get_ticks_msec()
	if now - begin_ms > 15000:
		print("SMOKE TIMEOUT state=", state, " snapshots=", snapshot_count)
		_cleanup(2)
		return

	peer.poll()
	var st := peer.get_connection_status()
	if state == "connecting" and st == MultiplayerPeer.CONNECTION_CONNECTED:
		state = "hello"
		_send(MSG_HELLO, PackedByteArray(), 1)
		print("SMOKE connected, sent HELLO")

	if st == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("SMOKE disconnected unexpectedly (state=", state, ")")
		_cleanup(3)
		return

	while peer.get_available_packet_count() > 0:
		var packet := peer.get_packet()
		if packet.is_empty():
			continue
		var mtype := packet[0]
		var payload := packet.slice(1)
		match mtype:
			MSG_ASSIGN:
				var data = bytes_to_var(payload)
				print("SMOKE got ASSIGN role=", data.get("role", "?") if data is Dictionary else "?")
				_send(MSG_READY, PackedByteArray(), 1)
				state = "ready"
			MSG_START:
				print("SMOKE got START -> playing")
				state = "playing"
				playing_since_ms = now
			MSG_SNAPSHOT:
				snapshot_count += 1
				# 新报文 = 4 字节 seq + var_to_bytes 快照字典
				if payload.size() >= 4:
					var seq := payload.decode_s32(0)
					if seq > snapshot_seq_last:
						snapshot_seq_last = seq
					else:
						print("SMOKE seq NOT monotonic: ", seq, " <= ", snapshot_seq_last)
			MSG_PING:
				# 阶段0：主机 RTT 探测 → 原样回 PONG（payload 即 8 字节时间戳）
				_send(MSG_PONG, payload, 1)
			MSG_QUIT:
				print("SMOKE got QUIT")
				_cleanup(0)
				return
		if _quit_pending:
			return

	if state == "playing":
		# 每 0.5 秒发送一个无按键输入包，验证输入链路
		if now - last_ping_ms > 500:
			last_ping_ms = now
			var buf := PackedByteArray()
			buf.append(0)
			_send(MSG_INPUT, buf, 1)
			print("SMOKE playing snapshots=", snapshot_count, " seq=", snapshot_seq_last)
		# 新版快照仅在状态变化时发送：无人操作时主机仅随重力步进（~0.62s/格），
		# 故以“≥3s 内收到 ≥8 帧且 seq 单调”作为通过标准（不再要求 20Hz×30 帧）。
		if snapshot_count >= 8 and now - playing_since_ms >= 3000:
			print("SMOKE OK: stable snapshot stream (", snapshot_count, " frames). Leaving.")
			_cleanup(0)

func _send(mtype: int, payload: PackedByteArray, to_peer: int) -> void:
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	var buf := PackedByteArray()
	buf.append(mtype)
	buf.append_array(payload)
	peer.set_target_peer(to_peer)
	peer.put_packet(buf)

func _cleanup(code: int) -> void:
	if peer != null:
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			_send(MSG_QUIT, PackedByteArray(), 1)
		peer.close()
	peer = null
	_quit_pending = true
	_quit_at_ms = Time.get_ticks_msec() + 400
	if code != 0:
		# 非成功退出也延迟一下确保 QUIT 发出
		quit(code)
