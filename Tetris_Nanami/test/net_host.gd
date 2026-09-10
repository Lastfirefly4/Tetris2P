extends SceneTree
# 无头主机 harness：实例化真实 Main.tscn 并在本地 NET_DEFAULT_PORT(8910) 开房，
# 配合 net_smoke.gd 走公网隧道做“开房/加入”联调（主机方）。
# 退出码：0=成功（对端加入→进入对局→验证后干净离开）；2=超时。
# 运行：godot --headless --path <project> -s res://test/net_host.gd

const DEFAULT_PORT := 8910

var host: Node = null
var begin_ms := 0
var playing_since := 0
var last_progress_ms := 0

func _initialize() -> void:
	begin_ms = Time.get_ticks_msec()
	Engine.max_fps = 120
	var packed := load("res://Main.tscn") as PackedScene
	host = packed.instantiate()
	root.add_child(host)
	host.call("_begin_host")
	print("HOST listening port=", host.get("net_listen_port"), " state=", host.get("net_state"))
	process_frame.connect(_tick)

func _tick() -> void:
	if host == null:
		quit(1)
		return
	var now := Time.get_ticks_msec()
	var ns: String = host.get("net_state")
	var ph: String = host.get("phase")
	if ph == "playing" and playing_since == 0:
		playing_since = now
		print("HOST match started (a client joined)")
	if now - last_progress_ms > 1000:
		last_progress_ms = now
		print("HOST progress state=", ns, " phase=", ph, " sent=", host.get("_snap_sent_count"),
			" rtt=", host.get("_rtt_est_ms"), " failed=", host.get("net_peer_failed_reason"))
	# 成功判定：进入对局后对端正常离开（客户端验证完毕后发送 QUIT）
	if playing_since > 0 and ns != "connected" and now - playing_since > 2000:
		print("HOST OK: peer joined, matched, then left cleanly. sent=", host.get("_snap_sent_count"))
		_cleanup(0)
		return
	if now - begin_ms > 30000:
		print("HOST TIMEOUT: no client completed the flow. state=", ns, " phase=", ph)
		_cleanup(2)

func _cleanup(code: int) -> void:
	if host != null:
		host.call("_close_net")
		root.remove_child(host)
		host.queue_free()
		host = null
	quit(code)
