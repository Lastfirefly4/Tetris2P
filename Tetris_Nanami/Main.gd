extends Node2D

const BOARD_WIDTH := 10
const BOARD_HEIGHT := 15
const CELL_SIZE := 32
const BASE_FALL_INTERVAL := 0.62
const ACCELERATED_PIECE_CHANCE := 0.10
const UNCONTROLLABLE_PIECE_CHANCE := 0.05
const ENERGY_BALL_LIFETIME := 20.0
const ENERGY_WIN_THRESHOLD := 100
const MIRROR_MAX_CHARGES := 3
const MIRROR_SPAWN_INTERVAL := 30.0
const LOCK_DELAY := 0.45
const MAN_HEIGHT := 2
const MAN_GRAVITY := 18.0
const MAN_JUMP_HEIGHT := 1.5
const MAN_JUMP_SPEED := -sqrt(2.0 * MAN_GRAVITY * MAN_JUMP_HEIGHT)
const MAN_DOUBLE_JUMP_HEIGHT := 1.0
const MAN_DOUBLE_JUMP_SPEED := -sqrt(2.0 * MAN_GRAVITY * MAN_DOUBLE_JUMP_HEIGHT)
const MAN_AIR_STEP_INTERVAL := 0.22
const DOUBLE_JUMP_COOLDOWN := 5.0
const SUFFOCATION_LIMIT := 30.0

const PIECES := [
	[[1, 1], [1, 1]],
	[[0, 2, 0], [2, 2, 2]],
	[[0, 3, 3], [3, 3, 0]],
	[[4, 4, 0], [0, 4, 4]],
	[[5, 5, 5, 5]],
	[[0, 0, 6], [6, 6, 6]],
	[[7, 0, 0], [7, 7, 7]],
]

const PIECE_COLORS := [
	Color(0, 0, 0, 0),
	Color("#ffe64a"),
	Color("#b660ff"),
	Color("#3fdc7a"),
	Color("#ff5c5c"),
	Color("#5ad7ff"),
	Color("#ff9d33"),
	Color("#4f7aff"),
]

const BOARD_BG := Color(0, 0, 0)
const GRID_COLOR := Color(1, 1, 1, 0.9)
const TEXT_COLOR := Color(237, 239, 245)
const MENU_TITLE := Color("#f4d7a9")
const MENU_HINT := Color("#c7d4eb")
const GAME_OVER_COLOR := Color("#ff6b6b")

# 菜单底部操作提示行：绘制与鼠标命中判定共用同一字符串 + 同一基线，
# 保证“点哪里 / 下划线画哪里”与文字位置永远不漂移。
const MENU_HINT_FONT_SIZE := 20
const JOIN_HINT_TEXT := "CLICK LEFT : CONNECT    RIGHT : BACK    CTRL+V : PASTE"
const HOST_PORT_HINT_TEXT := "CLICK LEFT : START HOST    RIGHT : BACK    CTRL+V : PASTE"

const NANAMI_TEXTURE := preload("res://nanami_sprite.png")
const SPRINT_TEXTURE := preload("res://icons/sprint.svg")
const BEAR_TEXTURE := preload("res://character/bear.png")
const WAIT_FRAMES := [
	preload("res://character/wait/frame_01.png"),
	preload("res://character/wait/frame_02.png"),
	preload("res://character/wait/frame_03.png"),
]
const LEFT_RUN_FRAMES := [
	preload("res://character/leftrun_3p/frame_01.png"),
	preload("res://character/leftrun_3p/frame_02.png"),
	preload("res://character/leftrun_3p/frame_03.png"),
]
const RIGHT_RUN_FRAMES := [
	preload("res://character/rightrun_3p/frame_01.png"),
	preload("res://character/rightrun_3p/frame_02.png"),
	preload("res://character/rightrun_3p/frame_03.png"),
]
const LEFT_JUMP_FRAMES := [
	preload("res://character/leftjump/frame_01.png"),
	preload("res://character/leftjump/frame_02.png"),
	preload("res://character/leftjump/frame_03.png"),
	preload("res://character/leftjump/frame_04.png"),
	preload("res://character/leftjump/frame_05.png"),
	preload("res://character/leftjump/frame_06.png"),
	preload("res://character/leftjump/frame_07.png"),
	preload("res://character/leftjump/frame_08.png"),
]
const RIGHT_JUMP_FRAMES := [
	preload("res://character/rightjump/frame_01.png"),
	preload("res://character/rightjump/frame_02.png"),
	preload("res://character/rightjump/frame_03.png"),
	preload("res://character/rightjump/frame_04.png"),
	preload("res://character/rightjump/frame_05.png"),
	preload("res://character/rightjump/frame_06.png"),
	preload("res://character/rightjump/frame_07.png"),
]
const MAN_ANIMATION_FPS := 10.0
const NAILS_TEXTURE := preload("res://icons/nails.svg")
const ROCKET_TEXTURE := preload("res://icons/rocket-flight.svg")
const BEAR_CRUEL_TEXTURE := preload("res://character/bear_cruel.png")
const BEAR_LAUGH_TEXTURE := preload("res://character/bear_laugh.png")
const BEAR_ANGRY_TEXTURE := preload("res://character/bear_angry.png")
const BEAR_FEAR_TEXTURE := preload("res://character/bear_fear.png")
const MENU_BGM_VOLUME_DB := -5.0
const INGAME_BGM_VOLUME_DB := -13.98
const SFX_VOLUME_DB := 3.86
const FOOTSTEP_CONCRETE_SFX := preload("res://Audio/footstep_concrete_000.ogg")
const FOOTSTEP_GRASS_SFX := preload("res://Audio/footstep_grass_001.ogg")
const JUMP_SFX := preload("res://Audio/sfx_jump.mp3")
const PIECE_APPEAR_SFX := preload("res://Audio/appear-online.wav")
const MENU_CLICK_SFX := preload("res://Audio/Menu Selection Click.wav")
const FAIL_SFX := preload("res://Audio/fail.wav")
var ingame_music: AudioStreamMP3 = preload("res://Music/ingame.mp3")
var menu_music: AudioStreamMP3 = preload("res://Music/menu.mp3")

var board: Array = []
var active_piece: Array = []
var active_piece_type: int = 0
var active_piece_accelerated: bool = false
var active_piece_uncontrollable: bool = false
var piece_x: int = 0
var piece_y: int = 0
var bag: Array = []

var man_x: int = 5
var man_y: float = BOARD_HEIGHT - 1
var man_velocity_y: float = 0.0
var man_alive: bool = true
var man_step_timer: float = 0.0
var man_last_direction: int = 0
var man_jump_count: int = 0
var man_air_direction: int = 0
var man_animation_name: String = "wait"
var man_animation_frame: int = 0
var man_animation_timer: float = 0.0
var double_jump_cooldown: float = 0.0
var suffocation_time: float = 0.0

var score: int = 0
var lines: int = 0
var survival: float = 0.0
var phase: String = "menu"
var over_reason: String = ""
var menu_background: Texture2D
var win_background: Texture2D
var bgm_player: AudioStreamPlayer
var sfx_players: Dictionary = {}
var energy_total: int = 0
var energy_balls: Array = []
var energy_spawn_timer: float = 0.0
var next_energy_spawn_interval: float = 0.0
var mirror_items: Array = []
var mirror_spawn_timer: float = 0.0
var mirror_charges: int = 0

var gravity_accumulator: float = 0.0
var lock_timer: float = 0.0
var block_step_timer: float = 0.0
var block_step_interval: float = 0.42
var step_interval: float = 0.14
var soft_drop_timer: float = 0.0
var soft_drop_interval: float = 1.0 / 30.0
var soft_drop_key_held: bool = false
var soft_drop_waiting_release: bool = false

# ===== 联机 / 输入抽象状态 =====
const NET_DEFAULT_PORT := 8910
const MSG_HELLO := 1
const MSG_ASSIGN := 2
const MSG_READY := 3
const MSG_START := 4
const MSG_INPUT := 5
const MSG_SNAPSHOT := 6
const MSG_QUIT := 8
const MSG_PING := 9
const MSG_PONG := 10
# P2 输入上行节流：状态无变化时的心跳周期（约 30Hz，原为每帧约 60Hz）
const NET_INPUT_SEND_INTERVAL := 1.0 / 30.0
# 主机侧上行看门狗：超过该时长未收到任何 INPUT 视为上行停摆（客户端异常/单向断流），
# 主动松开远端按键，避免主机抱着最后一帧位图让角色一直朝一个方向走。
const NET_INPUT_WATCHDOG_MS := 1000
# 阶段A：快照最小发送间隔（状态变化时 ~30Hz）；周期性全量校准（含棋盘，为阶段B不可靠通道预留）
const NET_SNAPSHOT_INTERVAL := 1.0 / 30.0
const NET_SNAPSHOT_CALIBRATE_EVERY := 2.0
# 阶段0：RTT 测量心跳周期
const NET_PING_INTERVAL := 1.0
const SNAPSHOT_PHASES: Array = ["playing", "paused", "game_over", "victory"]
const P1_ACTIONS := ["p1_left", "p1_right", "p1_rotate", "p1_soft", "p1_hard", "p1_mirror"]
const P2_ACTIONS := ["p2_left", "p2_right", "p2_jump"]
# 加入方角色键位（键码→上行位图）：A/D/W 为主，方向键为等价备选。
# 方向键仅在“加入方（client）”轮询，本地双人/主机模式不使用，避免与 P1 方块键冲突。
const P2_KEY_BITS := {
	KEY_A: 1, KEY_LEFT: 1,
	KEY_D: 2, KEY_RIGHT: 2,
	KEY_W: 4, KEY_UP: 4,
}
const GENERAL_ACTIONS := ["game_start", "game_restart", "game_quit", "game_pause", "menu_up", "menu_down"]

# 本机键盘负责谁：both（本地双人）/ p1（联机房主=方块）/ p2（联机加入者=角色）
var local_control: String = "both"
var net_role: String = "local"            # local | host | client
var net_peer: ENetMultiplayerPeer
var net_state: String = "idle"            # idle | listening | connecting | connected | failed
var net_remote_peer: int = 2
var net_my_role: String = "p1"
var net_peer_failed_reason: String = ""
var _host_ips: Array = []
var menu_mode: String = "main"            # main | host | join | wait_join | host_port
var menu_index: int = 0
var ip_buffer: String = ""
var host_port_buffer: String = ""         # 开房端口输入缓存（仅数字）
var _text_caret: int = 0                  # 文本输入光标位置（0..长度）
var _text_sel_anchor: int = -1            # 文本选区锚点；-1=无选区，==caret 时为纯光标
var _text_drag: bool = false              # 鼠标左键拖选进行中
var net_listen_port: int = NET_DEFAULT_PORT  # 本次开房实际监听的端口
var _input_frame: Dictionary = {}
var _input_prev: Dictionary = {}
var _snapshot_seq: int = 0
var _net_snapshot_timer: float = 0.0
var _net_input_timer: float = 0.0        # 客户端：输入发送节流计时
var _last_sent_input_bits: int = -1      # 客户端：上次已上报的输入位图（-1=尚未发送）
var _remote_p2_bits: int = 0             # 主机：最新收到的 P2 输入位图（包间保持按住）
var _last_input_recv_ms: int = 0         # 主机：最近一次收到 INPUT 的时刻（看门狗用）
var _client_key_latch: int = 0           # 加入方：本帧捕获到的按键“按下”沿（防低帧率丢极短点按）
var _prev_client_phase: String = ""
var _last_remote_anim_name: String = ""
var _last_net_receive_ms: int = 0
var _net_join_timeout_ms: int = 0
var net_join_timeout_ms: int = 12000     # 客户端等待“连上→开始对局”的最长时长（ms）

# —— 阶段0 网络诊断统计（RTT / 抖动 / 快照到达）——
var _rtt_est_ms: float = -1.0          # EMA RTT（ms）
var _rtt_jitter_ms: float = 0.0
var _rtt_ping_timer: float = 0.0
var _ping_outstanding: bool = false
var _ping_sent_ms: int = 0
var _snap_interval_avg_ms: float = -1.0  # 快照实际间隔 EMA（ms）
var _last_snap_event_ms: int = 0
var _snap_sent_count: int = 0          # 主机累计发送快照数
var _snap_recv_count: int = 0          # 客户端累计接收快照数
var _snap_lost_count: int = 0          # 客户端按 seq 间隙估算的丢失数
var _last_applied_snap_seq: int = -1   # 客户端最近应用快照的 seq（A1 去重）

# —— 阶段A 快照增量发送 ——
var _snapshot_force_next: bool = true  # 有离散事件或新局时，下一帧立即补发
var _last_sent_fingerprint: String = ""
var _last_full_snap_ms: int = -1       # 上次全量（含棋盘）快照时刻
var _board_dirty: bool = true          # 棋盘内容是否在两次快照之间变化

# —— 阶段A4 客户端渲染插值（仅加入方使用）——
var _vis_man_x: float = 0.0
var _vis_man_y: float = BOARD_HEIGHT - 1
var _vis_from_x: float = 0.0
var _vis_from_y: float = BOARD_HEIGHT - 1
var _vis_to_x: float = 0.0
var _vis_to_y: float = BOARD_HEIGHT - 1
var _vis_alpha: float = 1.0
var _vis_has_from: bool = false

func _ready() -> void:
	randomize()
	_setup_bgm()
	_setup_sfx()
	if ResourceLoader.exists("res://Staticpicture/background_main.jpg"):
		menu_background = load("res://Staticpicture/background_main.jpg") as Texture2D
	if ResourceLoader.exists("res://Staticpicture/CG_win.jpg"):
		win_background = load("res://Staticpicture/CG_win.jpg") as Texture2D
	_bind_inputs()
	reset_board()
	set_process(true)
	queue_redraw()

func _setup_bgm() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	add_child(bgm_player)
	menu_music.loop = true
	ingame_music.loop = true
	_play_bgm(menu_music)

func _setup_sfx() -> void:
	for sfx_name in ["footstep", "landing", "jump", "piece", "menu", "fail"]:
		var player := AudioStreamPlayer.new()
		player.name = "SFX_%s" % sfx_name
		player.volume_db = SFX_VOLUME_DB
		add_child(player)
		sfx_players[sfx_name] = player

func _play_sfx(sfx_name: String, stream: AudioStream) -> void:
	var player: AudioStreamPlayer = sfx_players.get(sfx_name)
	if player == null:
		return
	player.stream = stream
	player.play()

func _stop_sfx(sfx_name: String) -> void:
	var player: AudioStreamPlayer = sfx_players.get(sfx_name)
	if player == null:
		return
	player.stop()

func _play_bgm(stream: AudioStream) -> void:
	if bgm_player.stream == stream and bgm_player.playing:
		return
	bgm_player.volume_db = MENU_BGM_VOLUME_DB if stream == menu_music else INGAME_BGM_VOLUME_DB
	bgm_player.stream = stream
	bgm_player.play()

func _stop_bgm() -> void:
	bgm_player.stop()

func _play_fail_audio() -> void:
	_stop_bgm()
	_play_sfx("fail", FAIL_SFX)

func _bind_inputs() -> void:
	var actions := [
		"p1_left",
		"p1_right",
		"p1_rotate",
		"p1_soft",
		"p1_hard",
		"p1_mirror",
		"p2_left",
		"p2_right",
		"p2_jump",
		"game_start",
		"game_restart",
		"game_quit",
		"game_pause",
		"menu_up",
		"menu_down",
	]
	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

	_bind_key("p1_left", KEY_LEFT)
	_bind_key("p1_right", KEY_RIGHT)
	_bind_key("p1_rotate", KEY_UP)
	_bind_key("p1_soft", KEY_DOWN)
	_bind_key("p1_hard", KEY_SPACE)
	_bind_key("p1_mirror", KEY_X)
	_bind_key("p2_left", KEY_A)
	_bind_key("p2_right", KEY_D)
	_bind_key("p2_jump", KEY_W)
	_bind_key("game_start", KEY_ENTER)
	_bind_key("game_restart", KEY_R)
	_bind_key("game_quit", KEY_ESCAPE)
	_bind_key("game_pause", KEY_P)
	_bind_key("menu_up", KEY_UP)
	_bind_key("menu_down", KEY_DOWN)

func _bind_key(action_name: String, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	InputMap.action_add_event(action_name, event)

func _action_pressed(action: String) -> bool:
	return bool(_input_frame.get(action, false))

func _action_just_pressed(action: String) -> bool:
	return _action_pressed(action) and not bool(_input_prev.get(action, false))

func _input(event: InputEvent) -> void:
	# 加入方：锁存按键“按下”沿。逐帧轮询在低帧率/卡顿时会漏掉瞬间松开的点按，
	# 这里用事件级锁存保证“按下过就一定发得出去”（方向键备选键位同样锁存）。
	if net_role != "client":
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var code: int = key.physical_keycode if key.physical_keycode != 0 else key.keycode
	_client_key_latch |= int(P2_KEY_BITS.get(code, 0))

func _poll_local_inputs() -> void:
	# 每帧开头：保存上一帧按下状态，再收集本机键盘负责的动作
	_input_prev = _input_frame.duplicate()
	_input_frame.clear()
	var in_menu: bool = phase == "menu"
	if net_role == "local":
		for a in GENERAL_ACTIONS:
			_input_frame[a] = Input.is_action_pressed(a)
		for a in P1_ACTIONS:
			_input_frame[a] = Input.is_action_pressed(a)
		for a in P2_ACTIONS:
			_input_frame[a] = Input.is_action_pressed(a)
	else:
		# 联机：菜单/等待界面时本机可产生通用键；对局时通用键由主机产生
		if in_menu or net_role == "host":
			for a in GENERAL_ACTIONS:
				_input_frame[a] = Input.is_action_pressed(a)
		if net_role == "client":
			# 加入方固定操控角色（P2）：无论 local_control 如何都采集角色键，
			# 键位 = A/D/W（动作）或方向键（等价备选），并合并本帧锁存的按下沿。
			var latch := _client_key_latch
			_client_key_latch = 0
			_input_frame["p2_left"] = Input.is_action_pressed("p2_left") or Input.is_physical_key_pressed(KEY_LEFT) or (latch & 1) != 0
			_input_frame["p2_right"] = Input.is_action_pressed("p2_right") or Input.is_physical_key_pressed(KEY_RIGHT) or (latch & 2) != 0
			_input_frame["p2_jump"] = Input.is_action_pressed("p2_jump") or Input.is_physical_key_pressed(KEY_UP) or (latch & 4) != 0
		elif local_control == "p1":
			for a in P1_ACTIONS:
				_input_frame[a] = Input.is_action_pressed(a)
		elif local_control == "p2":
			for a in P2_ACTIONS:
				_input_frame[a] = Input.is_action_pressed(a)
	# 主机：输入已节流，两包之间把远端 P2 的“按住”状态补回本帧，
	# 避免主机逐帧采样把持续按键误判为频繁松开/按下（步进计时被反复清零）
	if net_role == "host":
		# 上行看门狗：长时间无 INPUT 就松开全部远端键（否则会“一直朝最后一帧的方向走”）
		if _last_input_recv_ms > 0 and Time.get_ticks_msec() - _last_input_recv_ms > NET_INPUT_WATCHDOG_MS:
			_remote_p2_bits = 0
		_input_frame["p2_left"] = (_remote_p2_bits & 1) != 0
		_input_frame["p2_right"] = (_remote_p2_bits & 2) != 0
		_input_frame["p2_jump"] = (_remote_p2_bits & 4) != 0

func _process(delta: float) -> void:
	_poll_local_inputs()
	_poll_network_always()
	_update_rtt_ping(delta)

	# 联机加入方：不运行本地模拟，仅处理网络快照/输入与渲染
	if net_role == "client":
		_process_client_frame(delta)
		queue_redraw()
		return

	if _action_just_pressed("game_quit"):
		_play_sfx("menu", MENU_CLICK_SFX)
		if phase == "menu":
			if menu_mode == "main":
				get_tree().quit()
			else:
				_leave_online()
		else:
			_return_to_menu()
		queue_redraw()
		return

	if phase == "menu":
		_handle_menu_input()
		queue_redraw()
		return

	if phase == "playing" and _action_just_pressed("game_pause"):
		_play_sfx("menu", MENU_CLICK_SFX)
		phase = "paused"
		_snapshot_force_next = true
		if net_role == "host":
			_send_snapshot_if_game(delta)
		queue_redraw()
		return
	if phase == "paused":
		if _action_just_pressed("game_pause"):
			_play_sfx("menu", MENU_CLICK_SFX)
			phase = "playing"
			_snapshot_force_next = true
		if net_role == "host":
			_send_snapshot_if_game(delta)
		queue_redraw()
		return

	if phase == "game_over":
		if _action_just_pressed("game_start") or _action_just_pressed("game_restart"):
			_play_sfx("menu", MENU_CLICK_SFX)
			start_game()
		if net_role == "host":
			_send_snapshot_if_game(delta)
		queue_redraw()
		return

	if phase == "victory":
		if _action_just_pressed("game_start") or _action_just_pressed("game_restart"):
			_play_sfx("menu", MENU_CLICK_SFX)
			start_game()
		if net_role == "host":
			_send_snapshot_if_game(delta)
		queue_redraw()
		return

	survival += delta
	_update_piece_gravity(delta)
	_handle_player_inputs(delta)
	_update_man_physics(delta)
	_update_man_animation(delta)
	_handle_block_inputs(delta)
	_check_crush()
	_update_suffocation(delta)
	_update_energy_balls(delta)
	_update_mirror_items(delta)
	if net_role == "host":
		_send_snapshot_if_game(delta)
	queue_redraw()

func start_game() -> void:
	_stop_sfx("fail")
	_remote_p2_bits = 0
	_last_input_recv_ms = 0
	_last_sent_fingerprint = ""
	_snapshot_force_next = true
	_last_full_snap_ms = -1
	reset_board()
	phase = "playing"
	_play_bgm(ingame_music)
	score = 0
	lines = 0
	survival = 0.0
	energy_total = 0
	energy_balls.clear()
	mirror_items.clear()
	mirror_spawn_timer = 0.0
	mirror_charges = 1
	energy_spawn_timer = 0.0
	next_energy_spawn_interval = randf_range(0.0, 20.0)
	man_alive = true
	man_x = 5
	man_y = BOARD_HEIGHT - 1
	man_velocity_y = 0.0
	man_jump_count = 0
	double_jump_cooldown = 0.0
	suffocation_time = 0.0
	_spawn_piece()

func _return_to_menu() -> void:
	_stop_sfx("fail")
	_close_net()
	reset_board()
	phase = "menu"
	menu_mode = "main"
	menu_index = 0
	net_role = "local"
	local_control = "both"
	_prev_client_phase = ""
	_last_remote_anim_name = ""
	_last_net_receive_ms = 0
	net_peer_failed_reason = ""
	score = 0
	lines = 0
	survival = 0.0
	energy_total = 0
	energy_balls.clear()
	energy_spawn_timer = 0.0
	next_energy_spawn_interval = 0.0
	mirror_items.clear()
	mirror_spawn_timer = 0.0
	mirror_charges = 0
	man_alive = true
	_play_bgm(menu_music)

func reset_board() -> void:
	board.clear()
	for _y in range(BOARD_HEIGHT):
		var row: Array = []
		row.resize(BOARD_WIDTH)
		row.fill(0)
		board.append(row)

	bag.clear()
	active_piece.clear()
	active_piece_type = 0
	active_piece_accelerated = false
	active_piece_uncontrollable = false
	piece_x = 0
	piece_y = 0
	gravity_accumulator = 0.0
	lock_timer = 0.0
	block_step_timer = 0.0
	man_step_timer = 0.0
	man_last_direction = 0
	man_air_direction = 0
	man_animation_name = "wait"
	man_animation_frame = 0
	man_animation_timer = 0.0
	man_velocity_y = 0.0
	man_jump_count = 0
	double_jump_cooldown = 0.0
	suffocation_time = 0.0
	soft_drop_timer = 0.0
	soft_drop_key_held = false
	soft_drop_waiting_release = false
	over_reason = ""
	_board_dirty = true

func _update_piece_gravity(delta: float) -> void:
	if active_piece.is_empty():
		return

	gravity_accumulator += delta
	var interval := BASE_FALL_INTERVAL * (0.5 if active_piece_accelerated or active_piece_uncontrollable else 1.0)
	if gravity_accumulator >= interval:
		if _can_move_piece(0, 1):
			piece_y += 1
			lock_timer = 0.0
		else:
			lock_timer += gravity_accumulator
			if lock_timer >= LOCK_DELAY:
				_lock_piece()
				return
		gravity_accumulator = 0.0

	if _can_move_piece(0, 1):
		return
	lock_timer += delta
	if lock_timer >= LOCK_DELAY:
		_lock_piece()

func _handle_block_inputs(delta: float) -> void:
	if active_piece.is_empty():
		return
	if active_piece_uncontrollable:
		return

	var soft_drop_pressed := _action_pressed("p1_soft")
	var new_soft_drop_press := soft_drop_pressed and not soft_drop_key_held
	if not soft_drop_pressed:
		soft_drop_key_held = false
		soft_drop_waiting_release = false
		soft_drop_timer = 0.0
	elif not soft_drop_key_held:
		soft_drop_key_held = true

	if soft_drop_pressed and not soft_drop_waiting_release:
		if new_soft_drop_press:
			_soft_drop()
			soft_drop_timer = soft_drop_interval
		else:
			soft_drop_timer -= delta
			if soft_drop_timer <= 0.0:
				_soft_drop()
				soft_drop_timer = soft_drop_interval

	if _action_just_pressed("p1_rotate"):
		_rotate_piece()
	if _action_just_pressed("p1_mirror"):
		_mirror_piece()
	if _action_just_pressed("p1_hard"):
		_hard_drop()

	var left := _action_pressed("p1_left")
	var right := _action_pressed("p1_right")

	if left != right:
		if _action_just_pressed("p1_left") or _action_just_pressed("p1_right"):
			_move_piece(-1 if left else 1)
			block_step_timer = block_step_interval
		else:
			block_step_timer -= delta
			if block_step_timer <= 0.0:
				_move_piece(-1 if left else 1)
				block_step_timer = block_step_interval
	else:
		block_step_timer = 0.0


func _handle_player_inputs(delta: float) -> void:
	var p2_left := _action_pressed("p2_left")
	var p2_right := _action_pressed("p2_right")
	var move_direction: int = -1 if p2_left and not p2_right else (1 if p2_right and not p2_left else 0)

	if _action_just_pressed("p2_jump") and _man_has_support():
		_play_sfx("jump", JUMP_SFX)
		man_velocity_y = MAN_JUMP_SPEED
		man_jump_count = 1
		man_air_direction = move_direction
		_mark_snapshot_event()
	elif _action_just_pressed("p2_jump") and man_jump_count == 1 and double_jump_cooldown <= 0.0:
		_play_sfx("jump", JUMP_SFX)
		man_velocity_y = MAN_DOUBLE_JUMP_SPEED
		man_jump_count = 2
		double_jump_cooldown = DOUBLE_JUMP_COOLDOWN
		if move_direction != 0:
			man_air_direction = move_direction
		_mark_snapshot_event()

	if move_direction != 0:
		var movement_interval: float = MAN_AIR_STEP_INTERVAL if not _man_has_support() else step_interval
		var direction_changed: bool = move_direction != man_last_direction
		man_step_timer -= delta
		if direction_changed or man_step_timer <= 0.0:
			_step_man(move_direction)
			man_step_timer = movement_interval
		man_last_direction = move_direction
	else:
		man_last_direction = 0
		man_step_timer = 0.0

func _update_man_physics(delta: float) -> void:
	if not man_alive:
		return

	if double_jump_cooldown > 0.0:
		double_jump_cooldown = maxf(0.0, double_jump_cooldown - delta)

	man_velocity_y += MAN_GRAVITY * delta
	var was_supported := _man_has_support()
	var previous_y: float = man_y
	var next_y: float = man_y + man_velocity_y * delta
	if _man_position_clear_at(man_x, next_y):
		man_y = next_y
		return

	if man_velocity_y > 0.0:
		var low: float = previous_y
		var high: float = next_y
		for _i in range(8):
			var middle: float = (low + high) * 0.5
			if _man_position_clear_at(man_x, middle):
				low = middle
			else:
				high = middle
		man_y = _get_man_support_y(low)
		if _man_has_support():
			man_jump_count = 0
			if not was_supported:
				_play_sfx("landing", FOOTSTEP_GRASS_SFX)
	else:
		man_y = previous_y
	man_velocity_y = 0.0

func _update_man_animation(delta: float) -> void:
	var next_animation_name := "wait"
	var animation_frames: Array = WAIT_FRAMES
	var animation_fps := 6.0

	if _man_has_support():
		if man_last_direction < 0:
			next_animation_name = "left_run"
			animation_frames = LEFT_RUN_FRAMES
			animation_fps = MAN_ANIMATION_FPS
		elif man_last_direction > 0:
			next_animation_name = "right_run"
			animation_frames = RIGHT_RUN_FRAMES
			animation_fps = MAN_ANIMATION_FPS
	else:
		if man_air_direction < 0:
			next_animation_name = "left_jump"
			animation_frames = LEFT_JUMP_FRAMES
			animation_fps = MAN_ANIMATION_FPS
		elif man_air_direction > 0:
			next_animation_name = "right_jump"
			animation_frames = RIGHT_JUMP_FRAMES
			animation_fps = MAN_ANIMATION_FPS

	if next_animation_name != man_animation_name:
		man_animation_name = next_animation_name
		man_animation_frame = 0
		man_animation_timer = 0.0

	man_animation_timer += delta
	var frame_duration: float = 1.0 / animation_fps
	while man_animation_timer >= frame_duration:
		man_animation_timer -= frame_duration
		man_animation_frame = (man_animation_frame + 1) % animation_frames.size()

func _get_man_support_y(previous_y: float) -> float:
	var support_y: int = BOARD_HEIGHT
	var first_candidate: int = clampi(ceili(previous_y - 0.001), 0, BOARD_HEIGHT - 1)
	for cell_y in range(first_candidate, BOARD_HEIGHT):
		if board[cell_y][man_x] != 0 or _piece_occupies(man_x, cell_y):
			support_y = cell_y
			break
	return float(support_y - 1)

func _fill_bag() -> void:
	if bag.is_empty():
		bag = []
		for i in range(PIECES.size()):
			bag.append(i)
		bag.shuffle()

func _spawn_piece() -> void:
	_mark_snapshot_event()
	if bag.is_empty():
		_fill_bag()

	if bag.is_empty():
		active_piece_type = randi() % PIECES.size()
	else:
		active_piece_type = int(bag.pop_front())

	active_piece.clear()
	for row in PIECES[active_piece_type]:
		var clone: Array = []
		clone.append_array(row)
		active_piece.append(clone)

	var special_roll := randf()
	active_piece_accelerated = special_roll < ACCELERATED_PIECE_CHANCE
	active_piece_uncontrollable = not active_piece_accelerated and special_roll < ACCELERATED_PIECE_CHANCE + UNCONTROLLABLE_PIECE_CHANCE

	piece_x = int((BOARD_WIDTH - active_piece[0].size()) / 2.0)
	piece_y = 0
	gravity_accumulator = 0.0
	lock_timer = 0.0

	if _collides(active_piece, piece_x, piece_y):
		phase = "game_over"
		over_reason = "方块堆到顶了"
		_play_fail_audio()
		return

	if _piece_hits_man(active_piece, piece_x, piece_y):
		_kill_man("七海千秋被处刑了")

func _collides(piece_matrix: Array, px: int, py: int) -> bool:
	for y in range(piece_matrix.size()):
		for x in range(piece_matrix[y].size()):
			if piece_matrix[y][x] == 0:
				continue
			var bx: int = px + x
			var by: int = py + y
			if bx < 0 or bx >= BOARD_WIDTH or by >= BOARD_HEIGHT:
				return true
			if by >= 0 and board[by][bx] != 0:
				return true
	return false

func _can_move_piece(dx: int, dy: int) -> bool:
	return not _collides(active_piece, piece_x + dx, piece_y + dy)

func _move_piece(dx: int) -> void:
	if phase != "playing" or active_piece.is_empty():
		return
	if not _collides(active_piece, piece_x + dx, piece_y):
		piece_x += dx
		_check_crush()

func _soft_drop() -> void:
	if phase != "playing" or active_piece.is_empty():
		return
	if _can_move_piece(0, 1):
		piece_y += 1
	else:
		_lock_piece()

func _hard_drop() -> void:
	if phase != "playing" or active_piece.is_empty():
		return
	while _can_move_piece(0, 1):
		piece_y += 1
	_lock_piece()

func _rotate_piece() -> void:
	if phase != "playing" or active_piece.is_empty():
		return

	var rotated: Array = []
	var rows: int = active_piece.size()
	var cols: int = active_piece[0].size()
	for x in range(cols):
		var row: Array = []
		for y in range(rows - 1, -1, -1):
			row.append(active_piece[y][x])
		rotated.append(row)

	for offset in [0, -1, 1, -2, 2]:
		if not _collides(rotated, piece_x + offset, piece_y):
			active_piece = rotated
			piece_x += offset
			_check_crush()
			return

func _mirror_piece() -> void:
	if phase != "playing" or active_piece.is_empty() or mirror_charges <= 0:
		return

	var mirrored: Array = []
	for row in active_piece:
		var mirrored_row: Array = row.duplicate()
		mirrored_row.reverse()
		mirrored.append(mirrored_row)

	if not _collides(mirrored, piece_x, piece_y):
		active_piece = mirrored
		mirror_charges -= 1
		_play_sfx("menu", MENU_CLICK_SFX)
		_check_crush()

func _lock_piece() -> void:
	if active_piece.is_empty() or phase != "playing":
		return

	if _piece_hits_man(active_piece, piece_x, piece_y):
		_kill_man("七海千秋被处刑了")
		return

	_play_sfx("piece", PIECE_APPEAR_SFX)

	soft_drop_waiting_release = true

	for y in range(active_piece.size()):
		for x in range(active_piece[y].size()):
			if active_piece[y][x] == 0:
				continue
			var bx: int = piece_x + x
			var by: int = piece_y + y
			if by >= 0 and by < BOARD_HEIGHT and bx >= 0 and bx < BOARD_WIDTH:
				board[by][bx] = active_piece[y][x]

	_board_dirty = true
	_mark_snapshot_event()
	score += 1
	active_piece.clear()
	_clear_rows()

	if phase == "playing":
		_spawn_piece()

func _clear_rows() -> void:
	var full_rows: Array = []
	for y in range(BOARD_HEIGHT):
		var full := true
		for x in range(BOARD_WIDTH):
			if board[y][x] == 0:
				full = false
				break
		if full:
			full_rows.append(y)

	if full_rows.is_empty():
		return

	var filtered: Array = []
	for y in range(BOARD_HEIGHT):
		if not full_rows.has(y):
			filtered.append(board[y])

	while filtered.size() < BOARD_HEIGHT:
		filtered.insert(0, [])
		for _i in range(BOARD_WIDTH):
			filtered[0].append(0)

	board = filtered
	_board_dirty = true
	_mark_snapshot_event()
	lines += full_rows.size()
	score += full_rows.size() * 10

	if man_alive:
		var under_rows := 0
		for row in full_rows:
			if float(row) > man_y:
				under_rows += 1
		if under_rows > 0:
			man_y += under_rows
			if man_y >= BOARD_HEIGHT:
				_kill_man("七海千秋被处刑了")
				return

	_check_crush()

func _man_occupied_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var top_cell: int = floori(man_y - 1.0 + 0.001)
	var bottom_cell: int = ceil(man_y + 1.0 - 0.001) - 1
	for cell_y in range(top_cell, bottom_cell + 1):
		if cell_y >= 0 and cell_y < BOARD_HEIGHT:
			result.append(Vector2i(man_x, cell_y))
	return result

func _piece_hits_man(piece_matrix: Array, px: int, py: int) -> bool:
	if not man_alive or piece_matrix.is_empty():
		return false

	for y in range(piece_matrix.size()):
		for x in range(piece_matrix[y].size()):
			if piece_matrix[y][x] == 0:
				continue
			var gx: int = px + x
			var gy: int = py + y
			if _piece_cell_hits_man(gx, gy):
				return true
	return false

func _piece_cell_hits_man(gx: int, gy: int) -> bool:
	var head_cell_y: int = floori(man_y - 1.0 + 0.001)
	return man_alive and gx == man_x and gy == head_cell_y

func _preview_cell_hits_man(gx: int, gy: int) -> bool:
	var top_cell_y: int = floori(man_y - 1.0 + 0.001)
	return man_alive and gx == man_x and (gy == top_cell_y or gy == top_cell_y + 1)

func _squashes_man() -> bool:
	if not man_alive or active_piece.is_empty():
		return false
	return _piece_hits_man(active_piece, piece_x, piece_y)

func _check_crush() -> void:
	if phase == "playing" and man_alive and _squashes_man():
		_kill_man("七海千秋被处刑了")

func _update_suffocation(delta: float) -> void:
	if phase != "playing" or not man_alive:
		return

	if _man_is_enclosed():
		suffocation_time = minf(SUFFOCATION_LIMIT, suffocation_time + delta)
		if suffocation_time >= SUFFOCATION_LIMIT:
			_kill_man("七海千秋窒息了")
	else:
		suffocation_time = 0.0

func _update_energy_balls(delta: float) -> void:
	if phase != "playing":
		return

	energy_spawn_timer += delta
	if energy_spawn_timer >= next_energy_spawn_interval:
		_spawn_energy_ball()
		energy_spawn_timer = 0.0
		next_energy_spawn_interval = randf_range(1.0, 20.0)

	for i in range(energy_balls.size() - 1, -1, -1):
		var ball: Dictionary = energy_balls[i]
		ball["life"] = float(ball["life"]) - delta
		if ball["life"] <= 0.0:
			energy_balls.remove_at(i)
			continue
		if _man_occupies_energy_cell(int(ball["x"]), int(ball["y"])):
			energy_total += int(ball["value"])
			energy_balls.remove_at(i)
			if energy_total >= ENERGY_WIN_THRESHOLD:
				_win_game()
				return

func _update_mirror_items(delta: float) -> void:
	if phase != "playing":
		return

	mirror_spawn_timer += delta
	if mirror_spawn_timer >= MIRROR_SPAWN_INTERVAL:
		_spawn_mirror_item()
		mirror_spawn_timer = 0.0

	for i in range(mirror_items.size() - 1, -1, -1):
		var item: Dictionary = mirror_items[i]
		item["life"] = float(item["life"]) - delta
		if item["life"] <= 0.0:
			mirror_items.remove_at(i)
			continue
		if _man_occupies_energy_cell(int(item["x"]), int(item["y"])):
			mirror_charges = mini(MIRROR_MAX_CHARGES, mirror_charges + 1)
			_play_sfx("piece", PIECE_APPEAR_SFX)
			mirror_items.remove_at(i)

func _get_collectible_candidates() -> Array:
	var top_settled_row: int = BOARD_HEIGHT
	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			if board[y][x] != 0:
				top_settled_row = min(top_settled_row, y)

	if top_settled_row == BOARD_HEIGHT:
		top_settled_row = BOARD_HEIGHT - 1

	# 生成区域：从堆顶上方第 4 行向下到棋盘底（高度上限比原范围下调一格，避免球刷在过高处）
	var allowed_min_y: int = max(0, top_settled_row - 4)
	var candidates: Array = []
	for y in range(allowed_min_y, BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			if board[y][x] != 0 or _piece_occupies(x, y) or _man_occupies_energy_cell(x, y):
				continue
			candidates.append(Vector2i(x, y))
	return candidates

func _man_occupies_energy_cell(gx: int, gy: int) -> bool:
	for cell in _man_occupied_cells():
		if cell.x == gx and cell.y == gy:
			return true
	return false

func _spawn_energy_ball() -> void:
	if phase != "playing":
		return

	var candidates: Array = _get_collectible_candidates()

	if candidates.is_empty():
		return

	var pick: Vector2i = candidates[randi() % candidates.size()]
	var energy_value: int = 10 if randf() < 0.5 else 20
	energy_balls.append({
		"x": int(pick.x),
		"y": int(pick.y),
		"value": energy_value,
		"life": ENERGY_BALL_LIFETIME,
		"color": Color("#5aa9ff") if energy_value == 10 else Color("#ff5c5c")
	})

func _spawn_mirror_item() -> void:
	if phase != "playing" or mirror_items.size() >= MIRROR_MAX_CHARGES:
		return

	var candidates: Array = _get_collectible_candidates()
	if candidates.is_empty():
		return

	var pick: Vector2i = candidates[randi() % candidates.size()]
	mirror_items.append({
		"x": int(pick.x),
		"y": int(pick.y),
		"life": ENERGY_BALL_LIFETIME,
	})

func _win_game() -> void:
	if phase == "victory":
		return
	phase = "victory"
	_mark_snapshot_event()
	_play_bgm(menu_music)
	energy_balls.clear()

func _man_is_enclosed() -> bool:
	var queue: Array[Vector2i] = []
	var visited: Dictionary = {}
	for cell in _man_occupied_cells():
		if not visited.has(cell):
			visited[cell] = true
			queue.append(cell)

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next_cell: Vector2i = current + direction
			if next_cell.y < 0:
				return false
			if next_cell.x < 0 or next_cell.x >= BOARD_WIDTH or next_cell.y >= BOARD_HEIGHT:
				continue
			if visited.has(next_cell) or _cell_is_solid(next_cell.x, next_cell.y):
				continue
			visited[next_cell] = true
			queue.append(next_cell)

	return true

func _cell_is_solid(x: int, y: int) -> bool:
	if board[y][x] != 0:
		return true
	return _piece_occupies(x, y)

func _kill_man(reason: String) -> void:
	if not man_alive:
		return
	man_alive = false
	phase = "game_over"
	_mark_snapshot_event()
	_play_fail_audio()
	over_reason = reason

func _step_man(dx: int) -> void:
	if not man_alive:
		return

	var candidate_x: int = man_x + dx
	if candidate_x < 0 or candidate_x >= BOARD_WIDTH:
		return

	if _man_position_clear_at(candidate_x, man_y):
		man_x = candidate_x
		_play_sfx("footstep", FOOTSTEP_CONCRETE_SFX)

func _man_position_clear_at(x: int, bottom_y: float) -> bool:
	if x < 0 or x >= BOARD_WIDTH or bottom_y - 1.0 < 0.0 or bottom_y + 1.0 > float(BOARD_HEIGHT):
		return false

	for cell_y in range(BOARD_HEIGHT):
		if not _man_overlaps_cell(x, cell_y, bottom_y, x):
			continue
		if board[cell_y][x] != 0 or _piece_occupies(x, cell_y):
			return false
	return true

func _man_overlaps_cell(x: int, cell_y: int, bottom_y: float, man_column: int) -> bool:
	if x != man_column or x < 0 or x >= BOARD_WIDTH or cell_y < 0 or cell_y >= BOARD_HEIGHT:
		return false
	var man_top: float = bottom_y - 1.0
	var man_bottom: float = bottom_y + 1.0
	return man_top < float(cell_y + 1) and man_bottom > float(cell_y)

func _man_has_support() -> bool:
	return not _man_position_clear_at(man_x, man_y + 0.02)

func _piece_occupies(x: int, y: int) -> bool:
	if active_piece.is_empty():
		return false
	for py in range(active_piece.size()):
		for px in range(active_piece[py].size()):
			if active_piece[py][px] != 0 and piece_x + px == x and piece_y + py == y:
				return true
	return false

func _get_landing_y() -> int:
	if active_piece.is_empty():
		return piece_y

	var landing_y := piece_y
	while true:
		if not _collides(active_piece, piece_x, landing_y + 1):
			landing_y += 1
		else:
			break
	return landing_y

func _get_boss_expression() -> Texture2D:
	# 窒息倒计时时 BOSS 幸灾乐祸地笑；之后按充能进度切换恐惧/愤怒，默认残忍
	if suffocation_time > 0.0:
		return BEAR_LAUGH_TEXTURE
	var energy_ratio: float = float(energy_total) / float(ENERGY_WIN_THRESHOLD)
	if energy_ratio >= 0.75:
		return BEAR_FEAR_TEXTURE
	if energy_ratio >= 0.5:
		return BEAR_ANGRY_TEXTURE
	return BEAR_CRUEL_TEXTURE

func _draw_double_jump_indicator(center: Vector2) -> void:
	var pink := Color("#ff79b7")
	var charge: float = 1.0 - double_jump_cooldown / DOUBLE_JUMP_COOLDOWN
	var icon_color := Color(1.0, 1.0, 1.0, 0.45 + charge * 0.55)

	draw_circle(center, 42.0, Color("#171922"))
	draw_texture_rect(SPRINT_TEXTURE, Rect2(center - Vector2(28.0, 28.0), Vector2(56.0, 56.0)), false, icon_color)

	draw_arc(center, 42.0, 0.0, TAU, 48, Color("#e5e7ef"), 2.0, true)
	if charge > 0.0:
		draw_arc(center, 42.0, -PI * 0.5, -PI * 0.5 + TAU * charge, 48, pink, 4.0, true)

func _draw_mirror_indicator(center: Vector2) -> void:
	draw_circle(center, 42.0, Color("#171922"))
	draw_texture_rect(NAILS_TEXTURE, Rect2(center - Vector2(28.0, 28.0), Vector2(56.0, 56.0)), false, Color.WHITE)
	draw_arc(center, 42.0, 0.0, TAU, 48, Color("#f4c542"), 3.0, true)
	_draw_hud_text(str(mirror_charges), center + Vector2(24.0, 29.0), 16, Color("#ffe36e"), 18.0, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_hud_text(text: String, text_position: Vector2, font_size: int, color: Color, width: float = -1.0, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(ThemeDB.fallback_font, text_position + Vector2(2.0, 2.0), text, alignment, width, font_size, Color(0.0, 0.0, 0.0, 0.55))
	draw_string(ThemeDB.fallback_font, text_position, text, alignment, width, font_size, color)

func _draw_hud_bar(rect: Rect2, ratio: float, fill_color: Color) -> void:
	var clamped_ratio: float = clampf(ratio, 0.0, 1.0)
	draw_rect(rect, Color("#242936"))
	draw_rect(Rect2(rect.position + Vector2(2.0, 2.0), Vector2(maxf(0.0, (rect.size.x - 4.0) * clamped_ratio), rect.size.y - 4.0)), fill_color)
	draw_line(rect.position + Vector2(0.0, rect.size.y), rect.position + Vector2(rect.size.x, rect.size.y), Color(1.0, 1.0, 1.0, 0.18), 1.0)

func _draw_net_diagnostics(origin_x: float, origin_y: float) -> void:
	# 阶段0：联机对局中在棋盘左侧空白处实时显示 RTT/抖动/快照频率/丢包（仅加入方统计丢包）
	if net_role == "local" or net_state != "connected":
		return
	if origin_x < 74.0:
		return
	var right := origin_x - 10.0
	var width := 62.0
	var x := right - width
	var y := origin_y + 16.0
	var font_size := 10
	var step := 14.0
	var dim := Color("#7f8aa0")
	var line_color := Color("#dbe4f0")

	_draw_hud_text("NET", Vector2(x, y), font_size, dim, width, HORIZONTAL_ALIGNMENT_RIGHT)
	y += step
	var rtt_label := "--"
	var rtt_col := dim
	if _rtt_est_ms >= 0.0:
		rtt_label = "%dms" % int(_rtt_est_ms)
		rtt_col = Color("#70e0a0") if _rtt_est_ms < 70.0 else (Color("#f4c542") if _rtt_est_ms < 180.0 else Color("#ff6b6b"))
	_draw_hud_text("RTT " + rtt_label, Vector2(x, y), font_size, rtt_col, width, HORIZONTAL_ALIGNMENT_RIGHT)
	y += step
	var jit_label := "--"
	if _rtt_jitter_ms > 0.0:
		jit_label = "%dms" % int(_rtt_jitter_ms)
	_draw_hud_text("JIT " + jit_label, Vector2(x, y), font_size, line_color, width, HORIZONTAL_ALIGNMENT_RIGHT)
	y += step
	var hz_label := "--"
	if _snap_interval_avg_ms > 0.0:
		hz_label = "%.0fHz" % (1000.0 / _snap_interval_avg_ms)
	_draw_hud_text("SNAP " + hz_label, Vector2(x, y), font_size, line_color, width, HORIZONTAL_ALIGNMENT_RIGHT)
	# 输入链路：加入方看自己发出的键位，主机看收到的远端键位（排查“按键无反应”的关键指标）
	y += step
	var bits: int = _remote_p2_bits if net_role == "host" else maxi(0, _last_sent_input_bits)
	_draw_hud_text("P2IN" if net_role == "host" else "P2OUT", Vector2(x, y), font_size, dim, width, HORIZONTAL_ALIGNMENT_RIGHT)
	y += step
	var bit_text := "%s%s%s" % [("L" if (bits & 1) != 0 else "-"), ("R" if (bits & 2) != 0 else "-"), ("J" if (bits & 4) != 0 else "-")]
	_draw_hud_text(bit_text, Vector2(x, y), font_size, line_color, width, HORIZONTAL_ALIGNMENT_RIGHT)
	if net_role == "client":
		y += step
		var total := _snap_recv_count + _snap_lost_count
		var loss_pct := 0
		if total > 0:
			loss_pct = int(100.0 * float(_snap_lost_count) / float(total))
		_draw_hud_text("LOSS %d%%" % loss_pct, Vector2(x, y), font_size, line_color, width, HORIZONTAL_ALIGNMENT_RIGHT)

func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	var board_scale: float = viewport_size.y / float(BOARD_HEIGHT * CELL_SIZE + 8.0)
	var cell_size: float = CELL_SIZE * board_scale
	var border_width: float = 4.0 * board_scale
	var board_size := Vector2(BOARD_WIDTH * cell_size, viewport_size.y - border_width * 2.0)
	var hud_width := 300.0
	var content_width := board_size.x + 44.0 + hud_width
	var origin_x: float = maxf(28.0, (viewport_size.x - content_width) * 0.5)
	var origin_y: float = border_width
	var hud_x: float = origin_x + board_size.x + 44.0
	var board_rect := Rect2(origin_x - 8.0, origin_y - 8.0, board_size.x + 16.0, board_size.y + 16.0)
	var hud_rect := Rect2(hud_x - 20.0, origin_y - 8.0, hud_width + 20.0, board_size.y + 16.0)

	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#11151c"))
	draw_rect(board_rect, BOARD_BG)
	var bear_source_size := BEAR_TEXTURE.get_size()
	var bear_scale: float = minf(board_size.x * 0.7 / bear_source_size.x, board_size.y * 0.7 / bear_source_size.y)
	var bear_size := bear_source_size * bear_scale
	var bear_position := Vector2(origin_x, origin_y) + (board_size - bear_size) * 0.5
	draw_texture_rect(BEAR_TEXTURE, Rect2(bear_position, bear_size), false, Color(1.0, 1.0, 1.0, 0.16))
	draw_rect(hud_rect, Color("#181d27"))
	draw_line(Vector2(hud_x - 20.0, origin_y - 8.0), Vector2(hud_x - 20.0, origin_y + board_size.y + 8.0), Color("#343d4d"), 2.0)
	for x in range(BOARD_WIDTH + 1):
		draw_line(Vector2(origin_x + x * cell_size, origin_y), Vector2(origin_x + x * cell_size, origin_y + board_size.y), GRID_COLOR)
	for y in range(BOARD_HEIGHT + 1):
		draw_line(Vector2(origin_x, origin_y + y * cell_size), Vector2(origin_x + board_size.x, origin_y + y * cell_size), GRID_COLOR)

	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			if board[y][x] == 0:
				continue
			var color: Color = PIECE_COLORS[board[y][x]]
			draw_rect(Rect2(origin_x + x * cell_size + 2.0 * board_scale, origin_y + y * cell_size + 2.0 * board_scale, cell_size - 4.0 * board_scale, cell_size - 4.0 * board_scale), color)

	if not active_piece.is_empty():
		var ghost_y := _get_landing_y()
		for y in range(active_piece.size()):
			for x in range(active_piece[y].size()):
				if active_piece[y][x] == 0:
					continue
				var gx: int = piece_x + x
				var gy: int = ghost_y + y
				if gy >= 0:
					var ghost_color: Color = PIECE_COLORS[active_piece[y][x]]
					ghost_color.a = 0.22
					var ghost_rect := Rect2(origin_x + gx * cell_size + 2.0 * board_scale, origin_y + gy * cell_size + 2.0 * board_scale, cell_size - 4.0 * board_scale, cell_size - 4.0 * board_scale)
					draw_rect(ghost_rect, ghost_color)

	if not active_piece.is_empty():
		for y in range(active_piece.size()):
			for x in range(active_piece[y].size()):
				if active_piece[y][x] == 0:
					continue
				var gx: int = piece_x + x
				var gy: int = piece_y + y
				if gy >= 0:
					draw_rect(Rect2(origin_x + gx * cell_size + 2.0 * board_scale, origin_y + gy * cell_size + 2.0 * board_scale, cell_size - 4.0 * board_scale, cell_size - 4.0 * board_scale), PIECE_COLORS[active_piece[y][x]])

	if man_alive:
		var visual_width_scale: float = 1.7 if man_animation_name == "wait" else 1.5
		var sprite_size := Vector2(cell_size * visual_width_scale, cell_size * 2.0)
		var draw_man_x: float = float(man_x)
		var draw_man_y: float = man_y
		if net_role == "client" and _vis_has_from:
			draw_man_x = _vis_man_x
			draw_man_y = _vis_man_y
		var sprite_pos := Vector2(origin_x + (draw_man_x + 0.5) * cell_size, origin_y + (draw_man_y - 1.0) * cell_size)
		sprite_pos.x -= sprite_size.x * 0.5
		var animation_frames: Array = WAIT_FRAMES
		match man_animation_name:
			"left_run":
				animation_frames = LEFT_RUN_FRAMES
			"right_run":
				animation_frames = RIGHT_RUN_FRAMES
			"left_jump":
				animation_frames = LEFT_JUMP_FRAMES
			"right_jump":
				animation_frames = RIGHT_JUMP_FRAMES
		var animation_frame: Texture2D = animation_frames[man_animation_frame]
		draw_texture_rect(animation_frame, Rect2(sprite_pos, sprite_size), false)

	if not active_piece.is_empty():
		var warning_y := _get_landing_y()
		for y in range(active_piece.size()):
			for x in range(active_piece[y].size()):
				if active_piece[y][x] == 0:
					continue
				var warning_x: int = piece_x + x
				var warning_cell_y: int = warning_y + y
				if warning_cell_y >= 0 and _preview_cell_hits_man(warning_x, warning_cell_y):
					var warning_rect := Rect2(origin_x + warning_x * cell_size + 2.0 * board_scale, origin_y + warning_cell_y * cell_size + 2.0 * board_scale, cell_size - 4.0 * board_scale, cell_size - 4.0 * board_scale)
					draw_rect(warning_rect, Color("#ff3030"), false, 3.0)

	var border_rect := Rect2(
		Vector2(origin_x - border_width * 0.5, origin_y - border_width * 0.5),
		Vector2(board_size.x + border_width, board_size.y + border_width)
	)
	draw_rect(border_rect, Color("#f4c542"), false, border_width)

	_draw_hud_text("RUN STATUS", Vector2(hud_x, origin_y + 29.0), 15, Color("#8f9bb2"))
	_draw_hud_text("%04d" % score, Vector2(hud_x, origin_y + 67.0), 30, Color("#f6f7fb"))
	_draw_hud_text("SCORE", Vector2(hud_x + 112.0, origin_y + 63.0), 12, Color("#8f9bb2"))
	_draw_hud_text("%02d" % lines, Vector2(hud_x + 178.0, origin_y + 67.0), 30, Color("#f6f7fb"))
	_draw_hud_text("LINES", Vector2(hud_x + 237.0, origin_y + 63.0), 12, Color("#8f9bb2"))
	draw_line(Vector2(hud_x, origin_y + 86.0), Vector2(hud_x + hud_width - 20.0, origin_y + 86.0), Color("#343d4d"), 1.0)

	var side_center := Vector2(hud_x + 78.0, origin_y + 155.0)
	var mirror_center := Vector2(hud_x + 202.0, origin_y + 155.0)
	_draw_double_jump_indicator(side_center)
	_draw_mirror_indicator(mirror_center)
	_draw_hud_text("DOUBLE JUMP", Vector2(side_center.x - 58.0, side_center.y + 62.0), 12, Color("#f6d7ea"), 116.0, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_hud_text("MIRROR", Vector2(mirror_center.x - 58.0, mirror_center.y + 62.0), 12, Color("#ffe36e"), 116.0, HORIZONTAL_ALIGNMENT_CENTER)

	var oxygen_ratio: float = 1.0 - suffocation_time / SUFFOCATION_LIMIT
	var oxygen_remaining: float = maxf(0.0, SUFFOCATION_LIMIT - suffocation_time)
	var oxygen_color: Color = Color("#ff5c6c").lerp(Color("#70e0a0"), clampf(oxygen_ratio, 0.0, 1.0))
	_draw_hud_text("OXYGEN", Vector2(hud_x, origin_y + 268.0), 13, Color("#aeb8ca"))
	_draw_hud_text("%.1f / %.1f s" % [oxygen_remaining, SUFFOCATION_LIMIT], Vector2(hud_x + 172.0, origin_y + 268.0), 13, oxygen_color, hud_width - 192.0, HORIZONTAL_ALIGNMENT_RIGHT)
	_draw_hud_bar(Rect2(hud_x, origin_y + 278.0, hud_width - 20.0, 14.0), oxygen_ratio, oxygen_color)
	if suffocation_time > 0.0:
		var warning_pulse: float = 0.5 + 0.5 * sin(survival * 7.0)
		draw_circle(Vector2(hud_x + hud_width - 30.0, origin_y + 255.0), 4.0 + warning_pulse * 2.0, Color(1.0, 0.35, 0.42, 0.35))

	# ===== HUD 下半部分：ROCKET FUEL 充能柱 + MONOKUMA BOSS 表情区 =====
	var fuel_ratio: float = clampf(float(energy_total) / float(ENERGY_WIN_THRESHOLD), 0.0, 1.0)
	var panel_top := origin_y + 306.0
	var panel_bottom := origin_y + 668.0
	draw_line(Vector2(hud_x, origin_y + 298.0), Vector2(hud_x + hud_width - 20.0, origin_y + 298.0), Color("#343d4d"), 1.0)

	# —— 标题行：火箭图标 + ROCKET FUEL + 充能数值 ——
	var rocket_source := ROCKET_TEXTURE.get_size()
	var rocket_scale := 44.0 / maxf(rocket_source.x, rocket_source.y)
	var rocket_draw := rocket_source * rocket_scale
	var fuel_col_x := hud_x + 27.0
	var rocket_center := Vector2(fuel_col_x, panel_top + 32.0)
	var rocket_bg := Rect2(rocket_center - Vector2(31.0, 31.0), Vector2(62.0, 62.0))
	draw_rect(rocket_bg, Color("#2b3344"))
	draw_rect(rocket_bg, Color("#4a5264"), false, 1.0)
	draw_texture_rect(ROCKET_TEXTURE, Rect2(rocket_center - rocket_draw * 0.5, rocket_draw), false, Color.WHITE)
	_draw_hud_text("ROCKET FUEL", Vector2(rocket_bg.end.x + 6.0, rocket_center.y + 6.0), 14, Color("#ffd27a"))
	_draw_hud_text("%d / %d" % [energy_total, ENERGY_WIN_THRESHOLD], Vector2(hud_x, rocket_center.y + 6.0), 14, Color("#71d9ff"), hud_width - 24.0, HORIZONTAL_ALIGNMENT_RIGHT)

	# —— 左侧：ROCKET FUEL 竖向充能柱（自下而上填充）——
	var bar_rect := Rect2(fuel_col_x - 19.0, rocket_bg.end.y + 4.0, 38.0, panel_bottom - (rocket_bg.end.y + 4.0) - 2.0)
	draw_rect(bar_rect, Color("#161b26"))
	var bar_inner := Rect2(bar_rect.position + Vector2(3.0, 3.0), bar_rect.size - Vector2(6.0, 6.0))
	draw_rect(bar_inner, Color("#242a3a"))
	for i in range(1, 5):
		var tick_y: float = bar_inner.position.y + bar_inner.size.y * (i / 5.0)
		draw_line(Vector2(bar_inner.position.x, tick_y), Vector2(bar_inner.end.x, tick_y), Color(1, 1, 1, 0.10), 1.0)
	var bar_fill_height: float = bar_inner.size.y * fuel_ratio
	if bar_fill_height > 0.0:
		var bar_fill := Rect2(bar_inner.position.x, bar_inner.end.y - bar_fill_height, bar_inner.size.x, bar_fill_height)
		draw_rect(bar_fill, Color("#ff8b3d"))
		draw_rect(Rect2(bar_fill.position.x, bar_fill.position.y, bar_fill.size.x, minf(5.0, bar_fill.size.y)), Color("#ffd27a"))
	draw_rect(bar_rect, Color("#4a5264"), false, 1.0)

	# —— 右侧：MONOKUMA BOSS 表情展示框 ——
	var boss_plate := Rect2(hud_x + 62.0, panel_top + 46.0, 218.0, panel_bottom - (panel_top + 46.0) - 2.0)
	draw_rect(boss_plate, Color("#141a25"))
	draw_rect(boss_plate, Color("#343d4d"), false, 1.0)
	var boss_tex := _get_boss_expression()
	var boss_source := boss_tex.get_size()
	var boss_scale: float = minf(186.0 / boss_source.x, 186.0 / boss_source.y)
	var boss_draw := boss_source * boss_scale
	var boss_center := boss_plate.position + Vector2(boss_plate.size.x * 0.5, boss_plate.size.y * 0.5)
	draw_texture_rect(boss_tex, Rect2(boss_center - boss_draw * 0.5, boss_draw), false)
	_draw_hud_text("MONOKUMA", Vector2(boss_plate.position.x, boss_plate.end.y - 12.0), 12, Color("#8f9bb2"), boss_plate.size.x, HORIZONTAL_ALIGNMENT_CENTER)

	for ball in energy_balls:
		var ball_x := origin_x + int(ball["x"]) * cell_size + cell_size / 2.0
		var ball_y := origin_y + int(ball["y"]) * cell_size + cell_size / 2.0
		draw_circle(Vector2(ball_x, ball_y), 9.0 * board_scale, ball["color"])
		draw_circle(Vector2(ball_x, ball_y), 5.0 * board_scale, Color(1, 1, 1, 0.65))

	for item in mirror_items:
		var item_x := origin_x + int(item["x"]) * cell_size + cell_size / 2.0
		var item_y := origin_y + int(item["y"]) * cell_size + cell_size / 2.0
		draw_circle(Vector2(item_x, item_y), 9.0 * board_scale, Color("#f4c542"))
		draw_circle(Vector2(item_x, item_y), 5.0 * board_scale, Color(1.0, 1.0, 0.75, 0.85))

	_draw_net_diagnostics(origin_x, origin_y)

	# 加入方：开局 8 秒内提示本机操控的角色键位（含方向键备选），之后自动隐去
	if net_role == "client" and phase == "playing" and survival < 8.0:
		var hint_w: float = minf(780.0, viewport_size.x - 40.0)
		var hint_x: float = (viewport_size.x - hint_w) * 0.5
		draw_rect(Rect2(hint_x, viewport_size.y - 46.0, hint_w, 32.0), Color(0.05, 0.06, 0.10, 0.55))
		_draw_hud_text("YOU : CHARACTER     A / D or LEFT / RIGHT : MOVE     W or UP : JUMP", Vector2(hint_x, viewport_size.y - 22.0), 20, Color("#dbe4f0"), hint_w, HORIZONTAL_ALIGNMENT_CENTER)

	if phase == "menu":
		var lay := _menu_layout()
		var menu_rect: Rect2 = lay["menu_rect"]
		if menu_background:
			draw_texture_rect(menu_background, menu_rect, false)
		else:
			draw_rect(menu_rect, Color(0.06, 0.08, 0.14, 1.0))
		draw_rect(menu_rect, Color(0.04, 0.05, 0.09, 0.32))

		var menu_center_y: float = lay["menu_center_y"]
		var menu_text_width: float = lay["menu_text_width"]
		var menu_text_x: float = lay["menu_text_x"]
		var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.003)

		if menu_mode == "main":
			draw_string(ThemeDB.fallback_font, Vector2(menu_text_x, menu_center_y - 110.0), "TETRIS NANAMI", HORIZONTAL_ALIGNMENT_CENTER, menu_text_width, 76, MENU_TITLE)
			var option_labels := ["LOCAL MODE", "ONLINE - HOST (BLOCKS)", "ONLINE - JOIN (PLAYER)"]
			var option_y := menu_center_y - 10.0
			var mouse_pos := get_viewport().get_mouse_position()
			var hover_row := -1
			for i in range(option_labels.size()):
				if Rect2(menu_text_x, option_y + i * 62.0 - 36.0, menu_text_width, 48.0).has_point(mouse_pos):
					hover_row = i
			for i in range(option_labels.size()):
				var selected := i == menu_index
				var label_y := option_y + i * 62.0
				if selected:
					draw_rect(Rect2(menu_text_x, label_y - 36.0, menu_text_width, 48.0), Color(1.0, 1.0, 1.0, 0.07))
				elif i == hover_row:
					draw_rect(Rect2(menu_text_x, label_y - 36.0, menu_text_width, 48.0), Color(1.0, 1.0, 1.0, 0.04))
				_draw_hud_text(option_labels[i], Vector2(menu_text_x, label_y), 28, Color("#f4e2c0") if selected else Color("#6f7a92"), menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
			_draw_hud_text("UP / DOWN / WHEEL : SELECT      ENTER / CLICK : CONFIRM", Vector2(menu_text_x, option_y + option_labels.size() * 62.0 + 8.0), 20, MENU_HINT, menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
			if not net_peer_failed_reason.is_empty():
				_draw_hud_text(net_peer_failed_reason, Vector2(menu_text_x, menu_center_y + 230.0), 22, GAME_OVER_COLOR, menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
		elif menu_mode == "host":
			draw_string(ThemeDB.fallback_font, Vector2(menu_text_x, menu_center_y - 150.0), "HOST ONLINE", HORIZONTAL_ALIGNMENT_CENTER, menu_text_width, 52, MENU_TITLE)
			# 地址可能很多（真实网卡 + VM + VPN），按每行最多 3 个换行显示
			var ip_lines: Array = _host_ip_lines()
			var row_y := menu_center_y - 88.0
			_draw_hud_text("YOUR IP :", Vector2(menu_text_x, row_y), 20, MENU_HINT, menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
			row_y += 34.0
			for i in range(ip_lines.size()):
				_draw_hud_text(str(ip_lines[i]), Vector2(menu_text_x, row_y), 24, TEXT_COLOR, menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
				row_y += 30.0
			row_y += 10.0
			_draw_hud_text("Port : %d        You control : BLOCKS (P1)" % net_listen_port, Vector2(menu_text_x, row_y), 24, MENU_HINT, menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
			row_y += 30.0
			_draw_hud_text("Player 2 (joiner) keys : A / D move    W jump", Vector2(menu_text_x, row_y), 20, Color("#6f7a92"), menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
			row_y += 48.0
			var wait_color := MENU_HINT.lerp(Color.WHITE, pulse)
			_draw_hud_text("WAITING FOR PLAYER 2 ...", Vector2(menu_text_x, row_y), 34, wait_color, menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
			row_y += 58.0
			if net_state == "failed":
				_draw_hud_text(net_peer_failed_reason, Vector2(menu_text_x, row_y), 22, GAME_OVER_COLOR, menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
				row_y += 34.0
			_draw_hud_text("ESC / CLICK : CANCEL", Vector2(menu_text_x, row_y), 20, Color("#6f7a92"), menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
		elif menu_mode == "join":
			draw_string(ThemeDB.fallback_font, Vector2(menu_text_x, menu_center_y - 120.0), "JOIN ONLINE", HORIZONTAL_ALIGNMENT_CENTER, menu_text_width, 48, MENU_TITLE)
			_draw_hud_text("Enter host :port  (empty port = %d)" % NET_DEFAULT_PORT, Vector2(menu_text_x, menu_center_y - 40.0), 24, MENU_HINT, menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
			_draw_text_input(ip_buffer, true)
			_draw_hud_text(JOIN_HINT_TEXT, Vector2(menu_text_x, _input_hint_baseline_y()), MENU_HINT_FONT_SIZE, Color("#6f7a92"), menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
		elif menu_mode == "host_port":
			draw_string(ThemeDB.fallback_font, Vector2(menu_text_x, menu_center_y - 120.0), "HOST ONLINE - PORT", HORIZONTAL_ALIGNMENT_CENTER, menu_text_width, 48, MENU_TITLE)
			_draw_hud_text("Enter port to listen (1-65535) :", Vector2(menu_text_x, menu_center_y - 40.0), 24, MENU_HINT, menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
			var port_display := host_port_buffer if not host_port_buffer.is_empty() else str(NET_DEFAULT_PORT)
			_draw_text_input(port_display, true)
			_draw_hud_text(HOST_PORT_HINT_TEXT, Vector2(menu_text_x, _input_hint_baseline_y()), MENU_HINT_FONT_SIZE, Color("#6f7a92"), menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
		elif menu_mode == "wait_join":
			if net_state == "failed":
				_draw_hud_text("CONNECTION FAILED", Vector2(menu_text_x, menu_center_y - 40.0), 40, GAME_OVER_COLOR, menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
				_draw_hud_text(net_peer_failed_reason, Vector2(menu_text_x, menu_center_y + 20.0), 24, TEXT_COLOR, menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
				_draw_hud_text("ESC / CLICK : BACK TO MENU", Vector2(menu_text_x, menu_center_y + 80.0), 20, Color("#6f7a92"), menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
			else:
				var pulse_color := MENU_HINT.lerp(Color.WHITE, pulse)
				_draw_hud_text("CONNECTING  ...", Vector2(menu_text_x, menu_center_y), 36, pulse_color, menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
				_draw_hud_text("You will control : PLAYER (P2)", Vector2(menu_text_x, menu_center_y + 70.0), 24, MENU_HINT, menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
				_draw_hud_text("Keys : A / D move    W jump    (LEFT / RIGHT / UP also work)", Vector2(menu_text_x, menu_center_y + 102.0), 20, Color("#6f7a92"), menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
				_draw_hud_text("ESC / CLICK : CANCEL", Vector2(menu_text_x, menu_center_y + 130.0), 20, Color("#6f7a92"), menu_text_width, HORIZONTAL_ALIGNMENT_CENTER)
		# 鼠标悬停提示：可点击操作区紧贴文字底部加下划线（区域按文字像素范围生成，不再漂移）
		var hover_pos := get_viewport().get_mouse_position()
		for area in _menu_action_areas():
			var hover_action: String = area["action"]
			if hover_action == "main_row" or hover_action.ends_with("_focus"):
				continue
			var ar: Rect2 = area["rect"]
			if ar.has_point(hover_pos):
				var uy: float = ar.end.y - 4.0
				draw_line(Vector2(ar.position.x + 6.0, uy), Vector2(ar.end.x - 6.0, uy), Color(1.0, 1.0, 1.0, 0.5), 2.0)
	elif phase == "game_over":
		var bg := Color(0.08, 0.06, 0.08, 0.7)
		draw_rect(Rect2(0, 0, viewport_size.x, viewport_size.y), bg)
		_draw_hud_text("GAME OVER", Vector2(0.0, 220.0), 42, GAME_OVER_COLOR, viewport_size.x, HORIZONTAL_ALIGNMENT_CENTER)
		_draw_hud_text("SCORE: %d" % score, Vector2(0.0, 290.0), 28, TEXT_COLOR, viewport_size.x, HORIZONTAL_ALIGNMENT_CENTER)
		_draw_hud_text(over_reason, Vector2(0.0, 330.0), 24, TEXT_COLOR, viewport_size.x, HORIZONTAL_ALIGNMENT_CENTER)
		_draw_hud_text("Press Enter or R to Restart", Vector2(0.0, 395.0), 22, MENU_HINT, viewport_size.x, HORIZONTAL_ALIGNMENT_CENTER)
	elif phase == "paused":
		var bg := Color(0.04, 0.04, 0.06, 0.78)
		draw_rect(Rect2(0, 0, viewport_size.x, viewport_size.y), bg)
		_draw_hud_text("PAUSED", Vector2(0.0, 250.0), 46, TEXT_COLOR, viewport_size.x, HORIZONTAL_ALIGNMENT_CENTER)
		_draw_hud_text("Press P to Resume", Vector2(0.0, 315.0), 24, MENU_HINT, viewport_size.x, HORIZONTAL_ALIGNMENT_CENTER)
	elif phase == "victory":
		var bg_rect := Rect2(Vector2.ZERO, viewport_size)
		if win_background:
			draw_texture_rect(win_background, bg_rect, false)
		else:
			draw_rect(bg_rect, Color(0.08, 0.08, 0.12, 1.0))
		draw_rect(bg_rect, Color(0.08, 0.08, 0.12, 0.8))
		var victory_font_size := 72
		_draw_hud_text("Execution Escape", Vector2(0.0, viewport_size.y * 0.5 + victory_font_size * 0.35), victory_font_size, TEXT_COLOR, viewport_size.x, HORIZONTAL_ALIGNMENT_CENTER)

func _serialize_state() -> Dictionary:
	return {
		"phase": phase,
		"score": score,
		"lines": lines,
		"man_x": man_x,
		"man_y": man_y,
		"man_alive": man_alive,
		"over_reason": over_reason,
		"piece_type": active_piece_type,
		"piece_accelerated": active_piece_accelerated,
		"piece_uncontrollable": active_piece_uncontrollable,
		"energy_total": energy_total,
		"piece_x": piece_x,
		"piece_y": piece_y,
	}

# ============================================================
#  阶段 2：快照（capture / apply）
# ============================================================
func _capture_snapshot(include_board: bool) -> Dictionary:
	var snap := {
		"phase": phase,
		"score": score,
		"lines": lines,
		"survival": survival,
		"over_reason": over_reason,
		"energy_total": energy_total,
		"active_piece": active_piece,
		"active_piece_type": active_piece_type,
		"active_piece_accelerated": active_piece_accelerated,
		"active_piece_uncontrollable": active_piece_uncontrollable,
		"piece_x": piece_x,
		"piece_y": piece_y,
		"man_x": man_x,
		"man_y": man_y,
		"man_velocity_y": man_velocity_y,
		"man_alive": man_alive,
		"man_last_direction": man_last_direction,
		"man_air_direction": man_air_direction,
		"man_animation_name": man_animation_name,
		"double_jump_cooldown": double_jump_cooldown,
		"suffocation_time": suffocation_time,
		"energy_balls": energy_balls,
		"mirror_items": mirror_items,
		"mirror_charges": mirror_charges,
	}
	# 阶段A3：棋盘只在变化或周期性校准时随包发送，客户端保留旧棋盘
	if include_board:
		snap["board"] = board
	return snap

func _apply_remote_snapshot(snap: Dictionary) -> void:
	var new_phase: String = snap.get("phase", "menu")
	if new_phase != _prev_client_phase and _prev_client_phase != "":
		if new_phase == "game_over":
			_play_fail_audio()
		elif new_phase == "victory":
			_play_bgm(menu_music)
		elif new_phase == "playing" and _prev_client_phase in ["game_over", "victory"]:
			_play_bgm(ingame_music)
	_prev_client_phase = new_phase
	phase = new_phase
	score = snap.get("score", score)
	lines = snap.get("lines", lines)
	survival = snap.get("survival", survival)
	over_reason = snap.get("over_reason", over_reason)
	energy_total = snap.get("energy_total", energy_total)
	board = snap.get("board", board)
	active_piece = snap.get("active_piece", active_piece)
	active_piece_type = snap.get("active_piece_type", active_piece_type)
	active_piece_accelerated = snap.get("active_piece_accelerated", active_piece_accelerated)
	active_piece_uncontrollable = snap.get("active_piece_uncontrollable", active_piece_uncontrollable)
	piece_x = snap.get("piece_x", piece_x)
	piece_y = snap.get("piece_y", piece_y)
	man_x = snap.get("man_x", man_x)
	man_y = snap.get("man_y", man_y)
	man_velocity_y = snap.get("man_velocity_y", man_velocity_y)
	man_alive = snap.get("man_alive", man_alive)
	man_last_direction = snap.get("man_last_direction", man_last_direction)
	man_air_direction = snap.get("man_air_direction", man_air_direction)
	double_jump_cooldown = snap.get("double_jump_cooldown", double_jump_cooldown)
	suffocation_time = snap.get("suffocation_time", suffocation_time)
	energy_balls = snap.get("energy_balls", energy_balls)
	mirror_items = snap.get("mirror_items", mirror_items)
	mirror_charges = snap.get("mirror_charges", mirror_charges)
	# 动画切换时重置本地帧；否则名称同步、帧由本端推进
	var anim_name: String = snap.get("man_animation_name", man_animation_name)
	if anim_name != _last_remote_anim_name:
		_last_remote_anim_name = anim_name
		man_animation_name = anim_name
		man_animation_frame = 0
		man_animation_timer = 0.0
	else:
		man_animation_name = anim_name
	_sync_remote_visual_target()

func _advance_remote_animation(delta: float) -> void:
	# 加入方不跑物理，只根据快照给出的动画名本地推进帧
	var frames: Array = WAIT_FRAMES
	var fps := 6.0
	match man_animation_name:
		"left_run":
			frames = LEFT_RUN_FRAMES
			fps = MAN_ANIMATION_FPS
		"right_run":
			frames = RIGHT_RUN_FRAMES
			fps = MAN_ANIMATION_FPS
		"left_jump":
			frames = LEFT_JUMP_FRAMES
			fps = MAN_ANIMATION_FPS
		"right_jump":
			frames = RIGHT_JUMP_FRAMES
			fps = MAN_ANIMATION_FPS
	man_animation_timer += delta
	var frame_duration := 1.0 / fps
	while man_animation_timer >= frame_duration:
		man_animation_timer -= frame_duration
		man_animation_frame = (man_animation_frame + 1) % frames.size()

# ============================================================
#  阶段 4：主菜单状态机 + 联机对局入口
# ============================================================
func _start_local_match() -> void:
	menu_mode = "main"
	menu_index = 0
	net_role = "local"
	local_control = "both"
	_close_net()
	start_game()

func _begin_host() -> void:
	net_role = "host"
	local_control = "p1"
	menu_mode = "host"
	net_state = "listening"
	net_remote_peer = 2
	_net_join_timeout_ms = 0
	_refresh_host_ips()
	net_peer = ENetMultiplayerPeer.new()
	var err := net_peer.create_server(net_listen_port, 1)
	if err != OK:
		net_peer_failed_reason = "无法在端口 %d 开启房间（可能被占用）" % net_listen_port
		net_peer = null
		net_state = "failed"
	queue_redraw()

func _refresh_host_ips() -> void:
	# 只显示加入方可用的地址：真实局域网 + Radmin 等虚拟组网网卡。
	# 过滤掉：APIPA 链路本地(169.254.*) 与 VMware/VirtualBox/Hyper-V/Docker 等虚拟机 NAT“主机侧”网卡。
	_host_ips.clear()
	var text := _run_ipconfig()
	if text.is_empty():
		# 非 Windows / 无 ipconfig 时回退到引擎枚举（仅做 IP 级过滤）
		for a in IP.get_local_addresses():
			var ip: String = a
			if ip.count(":") != 0 or ip.begins_with("127.") or _is_apipa_ip(ip):
				continue
			if not _host_ips.has(ip):
				_host_ips.append(ip)
		return
	# ipconfig 输出按适配器分块：非缩进行 = 适配器名，缩进行内含 “IPv4 地址 …”
	var adapter := ""
	for line in text.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.is_empty():
			continue
		if not line.begins_with(" ") and not line.begins_with("\t"):
			adapter = trimmed
			continue
		if trimmed.contains("IPv4") and trimmed.contains(":"):
			var parts := trimmed.split(":")
			var ip := parts[parts.size() - 1].strip_edges()
			if ip.contains(".") and not ip.contains(":") \
					and not _is_apipa_ip(ip) \
					and not _is_vm_adapter(adapter) \
					and not _host_ips.has(ip):
				_host_ips.append(ip)

func _run_ipconfig() -> String:
	var out: Array = []
	OS.execute("ipconfig", [], out)
	var text := ""
	for chunk in out:
		text += String(chunk) + "\n"
	return text

func _is_apipa_ip(ip: String) -> bool:
	# APIPA：网卡没拿到 DHCP 时 Windows 自动分配的链路本地地址(169.254.0.0/16)，他人无法连接
	return ip.begins_with("169.254.")

func _is_vm_adapter(adapter: String) -> bool:
	# 虚拟机/容器 NAT“主机侧”网卡对加入方无意义；
	# Hyper-V 默认交换机在 ipconfig 中名为 “vEthernet (Default Switch)”
	var a := adapter.to_lower()
	var keywords := [
		"vmware",
		"virtualbox",
		"hyper-v",
		"hyperv",
		"docker",
		"veethernet (default",
		"loopback",
		"bluetooth",
		"npcap",
	]
	for key in keywords:
		if a.contains(key):
			return true
	return false

func _begin_join_connect() -> void:
	# 支持 “主机:端口” 格式（SakuraFrp 等内网穿透会给随机远程端口/域名）；
	# 不带端口时缺省为 NET_DEFAULT_PORT。
	var addr := ip_buffer.strip_edges()
	var port := NET_DEFAULT_PORT
	if addr.is_empty():
		addr = "127.0.0.1"
	elif addr.contains(":"):
		var parts := addr.rsplit(":", true, 1)
		addr = parts[0].strip_edges()
		var port_text := parts[1].strip_edges()
		if port_text.is_valid_int():
			port = clampi(port_text.to_int(), 1, 65535)
	net_role = "client"
	local_control = "p2"
	menu_mode = "wait_join"
	net_state = "connecting"
	net_peer_failed_reason = ""
	_net_join_timeout_ms = Time.get_ticks_msec()
	net_peer = ENetMultiplayerPeer.new()
	var err := net_peer.create_client(addr, port)
	if err != OK:
		net_peer_failed_reason = "无法连接到 %s:%d" % [addr, port]
		net_peer = null
		net_state = "failed"
	queue_redraw()

func _start_online_game_on_client() -> void:
	reset_board()
	phase = "playing"
	_prev_client_phase = "playing"
	# 已进入对局：取消“等待加入”的超时计时，避免它在对局中被误触发
	_net_join_timeout_ms = 0
	_play_bgm(ingame_music)
	_last_applied_snap_seq = -1
	_vis_has_from = false
	_vis_alpha = 1.0
	queue_redraw()

func _handle_menu_input() -> void:
	match menu_mode:
		"main":
			if _action_just_pressed("menu_up"):
				_play_sfx("menu", MENU_CLICK_SFX)
				menu_index = (menu_index + 2) % 3
			elif _action_just_pressed("menu_down"):
				_play_sfx("menu", MENU_CLICK_SFX)
				menu_index = (menu_index + 1) % 3
			if _action_just_pressed("game_start"):
				_confirm_main_selection()
		"join":
			# 输入 IP 由 _unhandled_key_input 收集；Enter 发起连接
			if _action_just_pressed("game_start"):
				_play_sfx("menu", MENU_CLICK_SFX)
				_begin_join_connect()
		"host_port":
			# 输入端口由 _unhandled_key_input 收集（仅数字）；Enter 以此端口开房
			if _action_just_pressed("game_start"):
				_play_sfx("menu", MENU_CLICK_SFX)
				var port_text := host_port_buffer.strip_edges()
				net_listen_port = clampi(port_text.to_int(), 1, 65535) if port_text.is_valid_int() else NET_DEFAULT_PORT
				_begin_host()
		"wait_join":
			if net_state == "failed":
				net_peer_failed_reason = "未能连接到主机，请检查 IP 与主机是否开房"
				# 由玩家按 Esc 返回主菜单
		"host":
			pass

func _confirm_main_selection() -> void:
	# 键盘 Enter / 鼠标点击（已选中项再点或双击）确认主菜单当前项
	_play_sfx("menu", MENU_CLICK_SFX)
	match menu_index:
		0:
			_start_local_match()
		1:
			host_port_buffer = str(net_listen_port)
			menu_mode = "host_port"
			_text_input_reset()
		2:
			menu_mode = "join"
			_text_input_reset()
	queue_redraw()

func _menu_layout() -> Dictionary:
	# 各菜单屏共用版式（绘制与鼠标命中判定同源，避免漂移）
	var viewport_size := get_viewport_rect().size
	var menu_center_x := viewport_size.x * (5.0 / 6.0)
	var menu_center_y := viewport_size.y * 0.5
	var menu_text_width: float = minf(860.0, viewport_size.x - 40.0)
	var menu_text_center_x: float = clampf(menu_center_x - 40.0, menu_text_width * 0.5 + 20.0, viewport_size.x - menu_text_width * 0.5 - 20.0)
	var menu_text_x: float = menu_text_center_x - menu_text_width * 0.5
	return {
		"menu_rect": Rect2(Vector2.ZERO, viewport_size),
		"menu_center_x": menu_center_x,
		"menu_center_y": menu_center_y,
		"menu_text_width": menu_text_width,
		"menu_text_center_x": menu_text_center_x,
		"menu_text_x": menu_text_x,
	}

func _host_ip_lines() -> Array:
	# 与 HOST 屏绘制一致：真实网卡 IP 按每行最多 3 个换行显示
	var result: Array = []
	var parts: Array = []
	for ip in _host_ips:
		if ip == "127.0.0.1":
			continue
		parts.append(ip)
		if parts.size() == 3:
			result.append(", ".join(parts))
			parts = []
	if not parts.is_empty():
		result.append(", ".join(parts))
	if result.is_empty():
		result.append("127.0.0.1")
	return result

func _input_hint_baseline_y() -> float:
	# join / host_port 屏底部操作提示行的基线 y（绘制与命中判定同源）
	return float(_menu_layout()["menu_center_y"]) + 90.0

func _hint_span_rect(hint: String, span: String, x: float, baseline_y: float, width: float, font_size: int, pad: float = 6.0) -> Rect2:
	# hint 在 [x, x+width] 内居中绘制时，子串 span 的实际像素矩形；span 传空串=整行。
	# 命中判定与悬停下划线共用同一来源，避免与文字位置漂移。
	var font := ThemeDB.fallback_font
	var full_w: float = font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var left: float = x + (width - full_w) * 0.5
	var idx := 0
	var span_text := span
	if span.is_empty():
		span_text = hint
	else:
		idx = hint.find(span)
		if idx < 0:
			return Rect2()
	var x0: float = left + font.get_string_size(hint.substr(0, idx), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x1: float = x0 + font.get_string_size(span_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	# 竖直：基线之上一个字号 + 基线下方 0.4 字号，便于鼠标覆盖
	return Rect2(x0 - pad, baseline_y - float(font_size), (x1 - x0) + pad * 2.0, float(font_size) * 1.4)

func _menu_action_areas() -> Array:
	# 复刻各菜单屏版式，返回可点击区域（供鼠标点击判定与悬停高亮）
	var areas: Array = []
	var lay := _menu_layout()
	var menu_center_y: float = lay["menu_center_y"]
	var menu_text_x: float = lay["menu_text_x"]
	var menu_text_width: float = lay["menu_text_width"]
	var hint_y := _input_hint_baseline_y()
	var field_box: Rect2 = _text_field_geometry()["box"]
	match menu_mode:
		"main":
			var option_y := menu_center_y - 10.0
			for i in range(3):
				areas.append({
					"action": "main_row",
					"index": i,
					"rect": Rect2(menu_text_x, option_y + i * 62.0 - 36.0, menu_text_width, 48.0),
				})
		"join":
			areas.append({"action": "join_focus", "rect": field_box.grow(2.0)})
			areas.append({"action": "join_connect", "rect": _hint_span_rect(JOIN_HINT_TEXT, "CONNECT", menu_text_x, hint_y, menu_text_width, MENU_HINT_FONT_SIZE)})
			areas.append({"action": "join_back", "rect": _hint_span_rect(JOIN_HINT_TEXT, "BACK", menu_text_x, hint_y, menu_text_width, MENU_HINT_FONT_SIZE)})
		"host_port":
			areas.append({"action": "port_focus", "rect": field_box.grow(2.0)})
			areas.append({"action": "port_start", "rect": _hint_span_rect(HOST_PORT_HINT_TEXT, "START HOST", menu_text_x, hint_y, menu_text_width, MENU_HINT_FONT_SIZE)})
			areas.append({"action": "port_back", "rect": _hint_span_rect(HOST_PORT_HINT_TEXT, "BACK", menu_text_x, hint_y, menu_text_width, MENU_HINT_FONT_SIZE)})
		"host":
			var row_y := menu_center_y - 88.0
			row_y += 34.0 + 30.0 * _host_ip_lines().size() + 10.0 + 30.0 + 48.0 + 58.0
			if net_state == "failed":
				row_y += 34.0
			areas.append({"action": "host_cancel", "rect": _hint_span_rect("ESC / CLICK : CANCEL", "", menu_text_x, row_y, menu_text_width, MENU_HINT_FONT_SIZE)})
		"wait_join":
			if net_state == "failed":
				areas.append({"action": "wait_back", "rect": _hint_span_rect("ESC / CLICK : BACK TO MENU", "", menu_text_x, menu_center_y + 80.0, menu_text_width, MENU_HINT_FONT_SIZE)})
			else:
				areas.append({"action": "wait_cancel", "rect": _hint_span_rect("ESC / CLICK : CANCEL", "", menu_text_x, menu_center_y + 130.0, menu_text_width, MENU_HINT_FONT_SIZE)})
	return areas

func _handle_menu_click(pos: Vector2) -> void:
	for area in _menu_action_areas():
		var r: Rect2 = area["rect"]
		if not r.has_point(pos):
			continue
		var action: String = area["action"]
		match action:
			"main_row":
				# 单击即确认（旧版需先点一次选中、再点一次才响应，手感像“没反应”）
				menu_index = int(area["index"])
				_confirm_main_selection()
			"join_focus", "port_focus":
				# 点击输入框（拦截路径兜底）：回到纯光标
				_text_input_reset()
				queue_redraw()
			"join_connect":
				_begin_join_connect()
			"port_start":
				var port_text := host_port_buffer.strip_edges()
				net_listen_port = clampi(port_text.to_int(), 1, 65535) if port_text.is_valid_int() else NET_DEFAULT_PORT
				_begin_host()
			"join_back", "port_back", "host_cancel", "wait_cancel", "wait_back":
				_leave_online()  # 与键盘 Esc 返回主菜单行为一致
		return

func _unhandled_input(event: InputEvent) -> void:
	# 鼠标操作菜单：主菜单行/滚轮、子屏按钮、输入框光标与拖选文本
	if phase != "menu":
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _text_drag and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			var is_join := menu_mode == "join"
			_text_caret = _text_caret_from_x(is_join, mm.position.x)
			queue_redraw()
			get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.pressed:
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if not _try_text_field_mouse_press(mb.position):
				_handle_menu_click(mb.position)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if menu_mode == "main":
				_play_sfx("menu", MENU_CLICK_SFX)
				menu_index = (menu_index + 2) % 3 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else (menu_index + 1) % 3
				queue_redraw()
			get_viewport().set_input_as_handled()
	else:
		# 松开：结束拖选；未拖动（锚点==光标）则退化为纯光标
		if mb.button_index == MOUSE_BUTTON_LEFT and _text_drag:
			_text_drag = false
			if _text_sel_anchor >= 0 and _text_sel_anchor == _text_caret:
				_text_sel_anchor = -1
			queue_redraw()
			get_viewport().set_input_as_handled()

func _text_is_input_screen() -> bool:
	return menu_mode == "join" or menu_mode == "host_port"

func _text_field_allowed(ch: String, is_join: bool) -> bool:
	if is_join:
		# 允许字母（域名）、数字、点、冒号、连字符
		return (ch >= "0" and ch <= "9") or (ch >= "A" and ch <= "Z") or (ch >= "a" and ch <= "z") \
			or ch == "." or ch == ":" or ch == "-"
	# 端口：仅数字
	return ch >= "0" and ch <= "9"

func _text_field_font_size() -> int:
	return 34

func _text_field_geometry() -> Dictionary:
	# 输入框版式（join/host_port 同构；绘制与鼠标命中同源）
	var lay := _menu_layout()
	var input_y: float = lay["menu_center_y"] + 20.0
	var box_x: float = lay["menu_text_x"] + 40.0
	var box_w: float = lay["menu_text_width"] - 80.0
	var fs := _text_field_font_size()
	var box := Rect2(box_x, input_y - 25.0, box_w, 46.0)
	# 文字基线：数字/大写字母约占据基线上方 0.72em（视觉中心=基线-0.36em），
	# 取“基线=框中心+0.36em”使文字在框内垂直居中（旧版直接把基线放在 input_y，导致文字偏上）。
	var baseline: float = box.get_center().y + fs * 0.36
	# 光标/选区竖条：与文字同轴，上下各留 5px 内边距
	var caret_h: float = minf(fs * 0.94, box.size.y - 10.0)
	return {
		"input_y": input_y,
		"box": box,
		"font_size": fs,
		"text_baseline": baseline,
		"caret_top": box.get_center().y - caret_h * 0.5,
		"caret_height": caret_h,
	}

func _text_get(is_join: bool) -> String:
	return ip_buffer if is_join else host_port_buffer

func _text_set(is_join: bool, value: String) -> void:
	if is_join:
		ip_buffer = value
	else:
		host_port_buffer = value

func _text_max_len(is_join: bool) -> int:
	return 64 if is_join else 5

func _text_prefix_width(text: String, idx: int, font_size: int) -> float:
	idx = clampi(idx, 0, text.length())
	if idx <= 0:
		return 0.0
	return ThemeDB.fallback_font.get_string_size(text.substr(0, idx), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

func _text_text_left(display: String, box: Rect2, font_size: int) -> float:
	var text_w := ThemeDB.fallback_font.get_string_size(display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return box.position.x + (box.size.x - text_w) * 0.5

func _text_caret_from_x(is_join: bool, x: float) -> int:
	# 鼠标 x → 最近字符边界的光标下标
	var buf := _text_get(is_join)
	if buf.is_empty():
		return 0
	var fs := _text_field_font_size()
	var font := ThemeDB.fallback_font
	var g := _text_field_geometry()
	var box: Rect2 = g["box"]
	var text_left := _text_text_left(buf, box, fs)
	var local := x - text_left
	var acc := 0.0
	var best := 0
	var best_d := absf(local)
	for i in range(buf.length()):
		acc += font.get_string_size(buf.substr(i, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var d := absf(local - acc)
		if d < best_d:
			best_d = d
			best = i + 1
	return best

func _text_sel_has() -> bool:
	return _text_sel_anchor >= 0 and _text_sel_anchor != _text_caret

func _text_sel_bounds() -> Vector2i:
	if not _text_sel_has():
		return Vector2i(-1, -1)
	return Vector2i(mini(_text_sel_anchor, _text_caret), maxi(_text_sel_anchor, _text_caret))

func _text_input_reset() -> void:
	# 进入输入屏/重置：光标放到末尾（预填端口等可直接退格删除），无选区
	var is_join := menu_mode == "join"
	_text_caret = _text_get(is_join).length()
	_text_sel_anchor = -1
	_text_drag = false

func _text_clear_selection() -> void:
	_text_sel_anchor = -1

func _text_delete_range(is_join: bool, start: int, end: int) -> void:
	var buf := _text_get(is_join)
	_text_caret = start
	_text_set(is_join, buf.substr(0, start) + buf.substr(end))
	_text_clear_selection()
	queue_redraw()

func _text_backspace(is_join: bool) -> void:
	if _text_sel_has():
		var sb := _text_sel_bounds()
		_text_delete_range(is_join, sb.x, sb.y)
		return
	if _text_caret > 0:
		_text_caret -= 1
		var buf := _text_get(is_join)
		_text_set(is_join, buf.substr(0, _text_caret) + buf.substr(_text_caret + 1))
		queue_redraw()

func _text_delete_forward(is_join: bool) -> void:
	if _text_sel_has():
		var sb := _text_sel_bounds()
		_text_delete_range(is_join, sb.x, sb.y)
		return
	var buf := _text_get(is_join)
	if _text_caret < buf.length():
		_text_set(is_join, buf.substr(0, _text_caret) + buf.substr(_text_caret + 1))
		queue_redraw()

func _text_replace_with(is_join: bool, insertion: String) -> void:
	# 覆盖选区（若有）后在光标处插入；自动按屏过滤字符并截断到上限
	var start := _text_caret
	var end := _text_caret
	if _text_sel_has():
		var sb := _text_sel_bounds()
		start = sb.x
		end = sb.y
	var buf := _text_get(is_join)
	var head := buf.substr(0, start)
	var tail := buf.substr(end)
	var allowed := ""
	for ch in insertion:
		if _text_field_allowed(ch, is_join):
			allowed += ch
	var merged := head + allowed + tail
	var max_len := _text_max_len(is_join)
	if merged.length() > max_len:
		merged = merged.substr(0, max_len)
	_text_caret = clampi(head.length() + allowed.length(), 0, merged.length())
	_text_set(is_join, merged)
	_text_clear_selection()
	queue_redraw()

func _text_insert_char(is_join: bool, ch: String) -> void:
	if not _text_field_allowed(ch, is_join):
		return
	_text_replace_with(is_join, ch)

func _text_copy(is_join: bool) -> void:
	var content := ""
	var sb := _text_sel_bounds()
	if sb.x >= 0:
		content = _text_get(is_join).substr(sb.x, sb.y - sb.x)
	else:
		content = _text_get(is_join)
	if not content.is_empty():
		DisplayServer.clipboard_set(content)

func _text_cut(is_join: bool) -> void:
	if _text_sel_has():
		_text_copy(is_join)
		var sb := _text_sel_bounds()
		_text_delete_range(is_join, sb.x, sb.y)
		return
	# 无选区：剪切整段
	_text_copy(is_join)
	if not _text_get(is_join).is_empty():
		_text_set(is_join, "")
		_text_caret = 0
		_text_clear_selection()
		queue_redraw()

func _text_paste(is_join: bool) -> void:
	var clip := DisplayServer.clipboard_get()
	if clip.is_empty():
		return
	_text_replace_with(is_join, clip)

func _text_move_caret(is_join: bool, delta: int, extend: bool) -> void:
	var buf := _text_get(is_join)
	var target := clampi(_text_caret + delta, 0, buf.length())
	if target == _text_caret:
		return
	if not extend:
		_text_clear_selection()
	elif _text_sel_anchor < 0:
		_text_sel_anchor = _text_caret
	_text_caret = target
	queue_redraw()

func _text_jump_caret(is_join: bool, to_end: bool, extend: bool) -> void:
	if not extend:
		_text_clear_selection()
	elif _text_sel_anchor < 0:
		_text_sel_anchor = _text_caret
	_text_caret = _text_get(is_join).length() if to_end else 0
	queue_redraw()

func _try_text_field_mouse_press(pos: Vector2) -> bool:
	# 在输入框内按下：放置光标并进入拖选（拦截到则返回 true）
	if not _text_is_input_screen():
		return false
	var is_join := menu_mode == "join"
	for area in _menu_action_areas():
		var action: String = area["action"]
		if action != "join_focus" and action != "port_focus":
			continue
		var r: Rect2 = area["rect"]
		if not r.has_point(pos):
			continue
		_text_caret = _text_caret_from_x(is_join, pos.x)
		_text_sel_anchor = _text_caret
		_text_drag = true
		queue_redraw()
		return true
	return false

func _draw_text_input(display: String, caret_active: bool) -> void:
	# 输入框绘制：底框 + 选区高亮 + 居中文本 + 闪烁光标
	var g := _text_field_geometry()
	var fs: int = g["font_size"]
	var box: Rect2 = g["box"]
	var baseline: float = g["text_baseline"]
	var caret_top: float = g["caret_top"]
	var caret_h: float = g["caret_height"]
	draw_rect(box, Color(0.0, 0.0, 0.0, 0.22))
	draw_rect(box, Color(1.0, 1.0, 1.0, 0.10), false, 1.0)
	var text_left := _text_text_left(display, box, fs)
	# 选区（整段或部分）按字形范围高亮
	var sb := _text_sel_bounds()
	if sb.x >= 0 and not display.is_empty():
		var x0 := text_left + _text_prefix_width(display, sb.x, fs)
		var x1 := text_left + _text_prefix_width(display, sb.y, fs)
		draw_rect(Rect2(x0, caret_top, maxf(2.0, x1 - x0), caret_h), Color(0.44, 0.85, 1.0, 0.28))
	# 文本（居中于输入框，基线已按字体升降部校正）
	_draw_hud_text(display, Vector2(box.position.x, baseline), fs, Color("#f4e2c0"), box.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	# 闪烁光标
	if caret_active and not _text_drag and int(Time.get_ticks_msec() / 500.0) % 2 == 0:
		var cx := text_left + _text_prefix_width(display, _text_caret, fs)
		draw_rect(Rect2(cx + 1.0, caret_top, 2.0, caret_h), Color("#f4e2c0"))

func _unhandled_key_input(event: InputEvent) -> void:
	if not _text_is_input_screen():
		return
	var is_join := menu_mode == "join"
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	# 剪贴板：Ctrl+V 粘贴 / Ctrl+A 全选 / Ctrl+C 复制 / Ctrl+X 剪切
	if key_event.ctrl_pressed:
		match key_event.keycode:
			KEY_V:
				_text_paste(is_join)
				return
			KEY_A:
				if _text_get(is_join).is_empty():
					_text_clear_selection()
					_text_caret = 0
				else:
					_text_sel_anchor = 0
					_text_caret = _text_get(is_join).length()
				queue_redraw()
				return
			KEY_C:
				_text_copy(is_join)
				return
			KEY_X:
				_text_cut(is_join)
				return
	match key_event.keycode:
		KEY_BACKSPACE:
			_text_backspace(is_join)
			return
		KEY_DELETE:
			_text_delete_forward(is_join)
			return
		KEY_LEFT:
			_text_move_caret(is_join, -1, key_event.shift_pressed)
			return
		KEY_RIGHT:
			_text_move_caret(is_join, 1, key_event.shift_pressed)
			return
		KEY_HOME:
			_text_jump_caret(is_join, false, key_event.shift_pressed)
			return
		KEY_END:
			_text_jump_caret(is_join, true, key_event.shift_pressed)
			return
	if key_event.unicode == 0:
		return
	_text_insert_char(is_join, char(key_event.unicode))

# ============================================================
#  阶段 3：ENet 网络层
# ============================================================
func _net_send(msg_type: int, payload: PackedByteArray = PackedByteArray(), to_peer: int = 1) -> void:
	if net_peer == null or net_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	var buf := PackedByteArray()
	buf.append(msg_type)
	buf.append_array(payload)
	net_peer.set_target_peer(to_peer)
	net_peer.put_packet(buf)

func _update_rtt_ping(delta: float) -> void:
	if net_peer == null or net_state != "connected":
		return
	_rtt_ping_timer += delta
	if _rtt_ping_timer < NET_PING_INTERVAL:
		return
	_rtt_ping_timer = 0.0
	_ping_outstanding = true
	_ping_sent_ms = Time.get_ticks_msec()
	var payload := PackedByteArray()
	payload.resize(8)
	payload.encode_s64(0, _ping_sent_ms)
	_net_send(MSG_PING, payload, 0 if net_role == "host" else 1)

func _on_pong(payload: PackedByteArray) -> void:
	if not _ping_outstanding or payload.size() < 8:
		return
	_ping_outstanding = false
	var sent_ms: int = payload.decode_s64(0)
	var sample := float(Time.get_ticks_msec() - sent_ms)
	if sample < 0.0:
		return
	if _rtt_est_ms < 0.0:
		_rtt_est_ms = sample
		_rtt_jitter_ms = 0.0
	else:
		var diff := absf(sample - _rtt_est_ms)
		_rtt_jitter_ms = _rtt_jitter_ms * 0.7 + diff * 0.3
		_rtt_est_ms = _rtt_est_ms * 0.7 + sample * 0.3

func _poll_network_always() -> void:
	if net_peer == null:
		return
	net_peer.poll()
	var status := net_peer.get_connection_status()

	if net_state == "connecting":
		if status == MultiplayerPeer.CONNECTION_CONNECTED:
			net_state = "connected"
			_net_send(MSG_HELLO, PackedByteArray(), 1)
		elif status == MultiplayerPeer.CONNECTION_DISCONNECTED:
			net_state = "failed"
			net_peer_failed_reason = "连接失败：找不到主机"
			return

	if status == MultiplayerPeer.CONNECTION_DISCONNECTED and net_state == "connected":
		_leave_online("与对方的连接已断开")
		return

	if status != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	while net_peer.get_available_packet_count() > 0:
		var from_peer := net_peer.get_packet_peer()
		var packet := net_peer.get_packet()
		_handle_net_packet(packet, from_peer)

	_check_net_timeout()

func _handle_net_packet(packet: PackedByteArray, from_peer: int) -> void:
	if packet.is_empty():
		return
	_last_net_receive_ms = Time.get_ticks_msec()
	var mtype := packet[0]
	var payload := packet.slice(1)
	# 阶段0：PING/PONG 对两端对称，双方都测 RTT
	if mtype == MSG_PING:
		_net_send(MSG_PONG, payload, from_peer)
		return
	if mtype == MSG_PONG:
		_on_pong(payload)
		return
	if net_role == "host":
		_handle_host_packet(mtype, payload, from_peer)
	else:
		_handle_client_packet(mtype, payload)

func _handle_host_packet(mtype: int, payload: PackedByteArray, from_peer: int) -> void:
	match mtype:
		MSG_HELLO:
			net_remote_peer = from_peer
			net_state = "connected"
			_net_send(MSG_ASSIGN, var_to_bytes({"role": "p2"}), 0)
		MSG_READY:
			start_game()
			_net_send(MSG_START, PackedByteArray(), 0)
		MSG_INPUT:
			if payload.size() >= 1:
				_apply_remote_input_bitset(payload[0])
		MSG_QUIT:
			_leave_online("对方已退出游戏")

func _handle_client_packet(mtype: int, payload: PackedByteArray) -> void:
	match mtype:
		MSG_ASSIGN:
			var data = bytes_to_var(payload)
			if data is Dictionary:
				local_control = data.get("role", "p2")
			_net_send(MSG_READY, PackedByteArray(), 1)
		MSG_START:
			_start_online_game_on_client()
		MSG_SNAPSHOT:
			_receive_snapshot_payload(payload)
		MSG_QUIT:
			_leave_online("主机已结束游戏")

func _apply_remote_input_bitset(bits: int) -> void:
	_remote_p2_bits = bits
	_last_input_recv_ms = Time.get_ticks_msec()
	_input_frame["p2_left"] = (bits & 1) != 0
	_input_frame["p2_right"] = (bits & 2) != 0
	_input_frame["p2_jump"] = (bits & 4) != 0

func _send_local_input_if_playing(delta: float) -> void:
	if net_peer == null or net_state != "connected":
		return
	var bits := 0
	if _action_pressed("p2_left"):
		bits |= 1
	if _action_pressed("p2_right"):
		bits |= 2
	if _action_pressed("p2_jump"):
		bits |= 4
	# 位图变化（按下/松开沿）立即补发，心跳间隙的快速点按（如跳跃）不会漏
	if bits != _last_sent_input_bits:
		_last_sent_input_bits = bits
		_net_input_timer = 0.0
		_send_input_bits(bits)
		return
	# 状态无变化：按节流周期心跳上报当前状态（供主机保持按键并保活防超时）
	_net_input_timer += delta
	if _net_input_timer >= NET_INPUT_SEND_INTERVAL:
		_net_input_timer = 0.0
		_send_input_bits(bits)

func _send_input_bits(bits: int) -> void:
	if net_peer == null or net_state != "connected":
		return
	var buf := PackedByteArray()
	buf.append(bits)
	_net_send(MSG_INPUT, buf, 1)

func _send_snapshot_if_game(delta: float) -> void:
	if net_peer == null or net_state != "connected":
		return
	if not SNAPSHOT_PHASES.has(phase):
		return
	# 阶段A2：离散事件标记 → 立即补发；平时“状态变化 + 最小间隔”限流；完全静止不发
	if _snapshot_force_next:
		_snapshot_force_next = false
		_net_snapshot_timer = 0.0
		_send_current_snapshot()
		return
	_net_snapshot_timer += delta
	if _net_snapshot_timer < NET_SNAPSHOT_INTERVAL:
		return
	if not _snapshot_state_changed():
		_net_snapshot_timer = 0.0
		return
	_net_snapshot_timer = 0.0
	_send_current_snapshot()

func _mark_snapshot_event() -> void:
	# 阶段A2：离散事件（锁定/消行/出生/跳跃/胜负等）标记 → 下一帧立即补发快照
	_snapshot_force_next = true

func _snapshot_state_changed() -> bool:
	var fp := _snapshot_fingerprint()
	if fp == _last_sent_fingerprint:
		return false
	_last_sent_fingerprint = fp
	return true

func _snapshot_fingerprint() -> String:
	# 阶段A2：汇总影响客户端画面的状态；能量球/道具内容变化由该项捕获
	var parts: PackedStringArray = PackedStringArray()
	parts.append(phase)
	parts.append(str(score))
	parts.append(str(lines))
	parts.append(str(energy_total))
	parts.append(str(mirror_charges))
	parts.append(str(piece_x))
	parts.append(str(piece_y))
	parts.append(str(active_piece_type))
	parts.append(str(active_piece_accelerated))
	parts.append(str(active_piece_uncontrollable))
	parts.append(str(man_x))
	parts.append("%.2f" % man_y)
	parts.append(str(man_alive))
	parts.append(str(man_last_direction))
	parts.append(str(man_air_direction))
	parts.append(man_animation_name)
	parts.append("%.2f" % double_jump_cooldown)
	parts.append("%.2f" % suffocation_time)
	parts.append(_snapshot_piece_key())
	parts.append(_snapshot_collectible_key())
	return "|".join(parts)

func _snapshot_piece_key() -> String:
	var s := ""
	for row in active_piece:
		for v in row:
			s += str(v)
	return s

func _snapshot_collectible_key() -> String:
	var s := ""
	for b in energy_balls:
		s += "%d,%d,%d;" % [int(b["x"]), int(b["y"]), int(b["value"])]
	for it in mirror_items:
		s += "%d,%d;" % [int(it["x"]), int(it["y"])]
	return s

func _send_current_snapshot() -> void:
	if net_peer == null or net_state != "connected":
		return
	_snapshot_seq += 1
	_snap_sent_count += 1
	# 阶段A3：棋盘仅在变化或周期性校准时随包发送（客户端保留旧棋盘并覆盖变化行）
	var now := Time.get_ticks_msec()
	var include_board := _board_dirty
	if _last_full_snap_ms < 0 or now - _last_full_snap_ms >= int(NET_SNAPSHOT_CALIBRATE_EVERY * 1000.0):
		include_board = true
	if include_board:
		_last_full_snap_ms = now
	_board_dirty = false
	var snap := _capture_snapshot(include_board)
	var payload := PackedByteArray()
	payload.resize(4)
	payload.encode_s32(0, _snapshot_seq)
	payload.append_array(var_to_bytes(snap))
	_net_send(MSG_SNAPSHOT, payload, 0)
	# 登记刚发送内容的指纹，避免“事件补发后再按旧指纹误判一次变化”
	_last_sent_fingerprint = _snapshot_fingerprint()
	_record_snap_interval()

func _record_snap_interval() -> void:
	var now := Time.get_ticks_msec()
	if _last_snap_event_ms > 0:
		var iv := float(now - _last_snap_event_ms)
		if _snap_interval_avg_ms < 0.0:
			_snap_interval_avg_ms = iv
		else:
			_snap_interval_avg_ms = _snap_interval_avg_ms * 0.8 + iv * 0.2
	_last_snap_event_ms = now

func _receive_snapshot_payload(payload: PackedByteArray) -> void:
	# 报文 = 4 字节 seq + var_to_bytes 快照字典
	if payload.size() < 4:
		return
	var seq := payload.decode_s32(0)
	# 阶段A1：seq 单调去重（防乱序/重放导致状态倒带，为阶段B 不可靠通道预留）
	if seq <= _last_applied_snap_seq:
		return
	if _last_applied_snap_seq >= 0 and seq - _last_applied_snap_seq > 1:
		_snap_lost_count += seq - _last_applied_snap_seq - 1
	_last_applied_snap_seq = seq
	_snap_recv_count += 1
	_record_snap_interval()
	var snap = bytes_to_var(payload.slice(4))
	if snap is Dictionary:
		_apply_remote_snapshot(snap)

func _sync_remote_visual_target() -> void:
	# 阶段A4：把最新权威位置登记为插值起止点；离开对局直接贴合，避免漂移
	var target_x := float(man_x)
	var target_y := man_y
	if not _vis_has_from:
		_vis_man_x = target_x
		_vis_man_y = target_y
		_vis_from_x = target_x
		_vis_from_y = target_y
		_vis_to_x = target_x
		_vis_to_y = target_y
		_vis_has_from = true
		_vis_alpha = 1.0
	else:
		_vis_from_x = _vis_to_x
		_vis_from_y = _vis_to_y
		_vis_to_x = target_x
		_vis_to_y = target_y
		_vis_alpha = 0.0
	if phase != "playing":
		_vis_man_x = target_x
		_vis_man_y = target_y
		_vis_from_x = target_x
		_vis_from_y = target_y
		_vis_to_x = target_x
		_vis_to_y = target_y
		_vis_alpha = 1.0

func _advance_remote_visual(delta: float) -> void:
	# 阶段A4：客户端渲染位置在两个权威快照之间线性插值，缓解低快照率的“步进感”
	if not _vis_has_from:
		_vis_man_x = float(man_x)
		_vis_man_y = man_y
		return
	var duration := 0.033
	if _snap_interval_avg_ms > 0.0:
		duration = clampf(_snap_interval_avg_ms / 1000.0, 0.016, 0.12)
	_vis_alpha = minf(1.0, _vis_alpha + delta / duration)
	_vis_man_x = lerpf(_vis_from_x, _vis_to_x, _vis_alpha)
	_vis_man_y = lerpf(_vis_from_y, _vis_to_y, _vis_alpha)

func _process_client_frame(delta: float) -> void:
	# 本地退出/断开
	if Input.is_action_just_pressed("game_quit"):
		_leave_online("已离开游戏")
		return
	if phase == "playing" or phase == "paused":
		_advance_remote_animation(delta)
	if phase == "playing":
		_advance_remote_visual(delta)
		if _action_just_pressed("p2_jump"):
			_play_sfx("jump", JUMP_SFX)
		_send_local_input_if_playing(delta)

func _check_net_timeout() -> void:
	if net_peer == null:
		return
	var now := Time.get_ticks_msec()
	# 客户端从发起连接到进入对局的最长等待。
	# 注意：必须限定在“等待加入”菜单屏内——对局中若误触发会把 net_state 打成 failed，
	# 加入方所有上行流量（输入/心跳）静默停摆，而快照仍在单向推送（曾导致“角色突然不能操作”）。
	if net_role == "client" and net_state in ["connecting", "connected"] and phase == "menu" and menu_mode == "wait_join":
		if _net_join_timeout_ms > 0 and now - _net_join_timeout_ms > net_join_timeout_ms:
			net_state = "failed"
			net_peer_failed_reason = "连接超时：主机未响应"
			return
	# 对局中长时间（10 秒）无数据才判定掉线，容忍高延迟网络抖动
	var in_match: bool = net_state == "connected" and phase in ["playing", "paused", "game_over", "victory"]
	if in_match and _last_net_receive_ms > 0 and now - _last_net_receive_ms > 10000:
		_leave_online("网络连接超时")

func _leave_online(reason: String = "") -> void:
	# 有连接时通知对端（房主广播 0，加入方发往主机 1）
	if net_peer != null and net_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_net_send(MSG_QUIT, PackedByteArray(), 0 if net_role == "host" else 1)
	_close_net()
	_stop_sfx("fail")
	reset_board()
	phase = "menu"
	menu_mode = "main"
	menu_index = 0
	net_role = "local"
	local_control = "both"
	_prev_client_phase = ""
	_last_remote_anim_name = ""
	_last_net_receive_ms = 0
	_net_join_timeout_ms = 0
	net_peer_failed_reason = reason
	_play_bgm(menu_music)
	queue_redraw()

func _close_net() -> void:
	if net_peer != null:
		net_peer.close()
	net_peer = null
	net_state = "idle"
	_remote_p2_bits = 0
	_last_input_recv_ms = 0
	_net_input_timer = 0.0
	_last_sent_input_bits = -1
	_ping_outstanding = false
	_last_applied_snap_seq = -1
	_vis_has_from = false
	_vis_alpha = 1.0
	_snapshot_force_next = true
