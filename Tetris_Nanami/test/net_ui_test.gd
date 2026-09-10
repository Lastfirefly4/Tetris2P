extends SceneTree
# 菜单鼠标 + 文本输入逻辑 headless 单测：实例化真实 Main.tscn，
# 直接注入 InputEventKey / 调用鼠标点击处理，断言菜单状态机与输入行为。
# 运行：godot --headless --path <project> -s res://test/net_ui_test.gd

var main: Node = null
var fails: Array = []

func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fails.append(label)

func _initialize() -> void:
	Engine.max_fps = 120
	var packed := load("res://Main.tscn") as PackedScene
	main = packed.instantiate()
	root.add_child(main)
	# 等 2 帧让 _ready 就绪
	process_frame.connect(_tick)
	_frame = 0

var _frame := 0

func _tick() -> void:
	_frame += 1
	if _frame == 3:
		_run_tests()
		_cleanup(0 if fails.is_empty() else 1)

func _key(kc: Key, unicode: int = 0, ctrl: bool = false) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = kc
	ev.unicode = unicode
	ev.ctrl_pressed = ctrl
	ev.pressed = true
	ev.echo = false
	return ev

func _mbtn(x: float, y: float, pressed: bool) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = Vector2(x, y)
	ev.pressed = pressed
	return ev

func _motion(x: float, y: float) -> InputEventMouseMotion:
	var ev := InputEventMouseMotion.new()
	ev.position = Vector2(x, y)
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	return ev

func _click_at_area(action: String) -> void:
	var areas: Array = main.call("_menu_action_areas")
	for a in areas:
		if a["action"] == action:
			var r: Rect2 = a["rect"]
			main.call("_handle_menu_click", r.get_center())
			return
	_check(false, "area not found: " + action)
func _run_tests() -> void:
	_check(main.get("phase") == "menu", "boots into menu phase")
	_check(main.get("menu_mode") == "main", "menu_mode is main at boot")

	# —— 鼠标单击主菜单第二项：单击即确认（旧版需先选中再点一次）——
	var areas: Array = main.call("_menu_action_areas")
	var host_row: Rect2 = Rect2()
	for a in areas:
		if a["action"] == "main_row" and a["index"] == 1:
			host_row = a["rect"]
	_check(host_row.size.x > 0, "found HOST row area")
	main.call("_handle_menu_click", host_row.get_center())
	_check(main.get("menu_index") == 1, "single click selects HOST row")
	_check(main.get("menu_mode") == "host_port", "single click confirms immediately -> host_port")

	# —— 端口输入：退格 / Ctrl+A 全选 / 覆盖 / 光标中插 / Delete / 方向键 ——
	main.set("host_port_buffer", "8910")
	main.call("_text_input_reset")
	main.call("_unhandled_key_input", _key(KEY_BACKSPACE))
	_check(main.get("host_port_buffer") == "891", "backspace deletes one char")
	main.call("_unhandled_key_input", _key(KEY_A, 0, true))
	_check(main.get("_text_caret") == 3 and main.get("_text_sel_anchor") == 0, "Ctrl+A selects all (anchor=0 caret=len)")
	main.call("_unhandled_key_input", _key(KEY_7, 55))
	_check(main.get("host_port_buffer") == "7", "typing replaces whole selection")
	_check(main.get("_text_sel_anchor") == -1, "typing clears selection")
	# 光标中插
	main.set("host_port_buffer", "89")
	main.set("_text_caret", 1)
	main.call("_text_clear_selection")
	main.call("_unhandled_key_input", _key(KEY_5, 53))
	_check(main.get("host_port_buffer") == "859", "typing inserts at caret")
	_check(main.get("_text_caret") == 2, "caret advances after insert")
	main.call("_unhandled_key_input", _key(KEY_LEFT))
	main.call("_unhandled_key_input", _key(KEY_7, 55))
	_check(main.get("host_port_buffer") == "8759", "left arrow + type inserts in middle")
	# Delete / Home
	main.set("host_port_buffer", "12345")
	main.call("_text_input_reset")
	main.call("_unhandled_key_input", _key(KEY_DELETE))
	_check(main.get("host_port_buffer") == "12345", "delete at end does nothing")
	main.call("_unhandled_key_input", _key(KEY_HOME))
	main.call("_unhandled_key_input", _key(KEY_DELETE))
	_check(main.get("host_port_buffer") == "2345", "delete removes char after caret")
	# 非数字不允许
	main.set("host_port_buffer", "")
	main.call("_text_input_reset")
	main.call("_unhandled_key_input", _key(KEY_A, 65))  # 'A'
	_check(main.get("host_port_buffer") == "", "port field rejects letters")
	main.call("_unhandled_key_input", _key(KEY_5, 53))
	_check(main.get("host_port_buffer") == "5", "port field accepts digits")

	# —— 鼠标拖选：按下定位 → 拖动选区 → 松开保持 → 键入覆盖选区 ——
	var tg: Dictionary = main.call("_text_field_geometry")
	var tbox: Rect2 = tg["box"]
	var ty: float = tbox.get_center().y
	main.set("host_port_buffer", "8910")
	main.call("_text_input_reset")
	main.call("_unhandled_input", _mbtn(tbox.position.x + 2.0, ty, true))
	_check(main.get("_text_caret") == 0 and main.get("_text_drag") == true, "press in field places caret & starts drag")
	main.call("_unhandled_input", _motion(tbox.end.x - 2.0, ty))
	var sb: Vector2i = main.call("_text_sel_bounds")
	_check(sb.x == 0 and sb.y == 4, "drag right selects whole buffer")
	main.call("_unhandled_input", _mbtn(tbox.end.x - 2.0, ty, false))
	_check(main.get("_text_drag") == false, "release ends drag")
	_check(main.call("_text_sel_has") == true, "selection kept after release")
	main.call("_unhandled_key_input", _key(KEY_9, 57))
	_check(main.get("host_port_buffer") == "9", "typing replaces mouse selection")
	# 无拖动的单击退化为纯光标
	main.call("_unhandled_input", _mbtn(tbox.end.x - 2.0, ty, true))
	main.call("_unhandled_input", _mbtn(tbox.end.x - 2.0, ty, false))
	_check(main.get("_text_sel_anchor") == -1, "plain click leaves caret only")

	# —— 加入屏输入：域名/冒号/点/连字符 ——
	main.set("menu_mode", "join")
	main.call("_text_input_reset")
	main.set("ip_buffer", "")
	main.call("_unhandled_key_input", _key(KEY_F, 70))
	main.call("_unhandled_key_input", _key(KEY_R, 114))
	main.call("_unhandled_key_input", _key(KEY_MINUS, 45))
	main.call("_unhandled_key_input", _key(KEY_P, 112))
	main.call("_unhandled_key_input", _key(KEY_COLON, 58))
	main.call("_unhandled_key_input", _key(KEY_2, 50))
	_check(main.get("ip_buffer") == "Fr-p:2", "join field accepts domain/punct chars")
	main.call("_unhandled_key_input", _key(KEY_SPACE, 32))
	_check(main.get("ip_buffer") == "Fr-p:2", "join field rejects spaces")

	# —— 鼠标点击 join 屏 CONNECT 区域 → 进入 wait_join/connecting ——
	main.set("ip_buffer", "127.0.0.1")
	main.call("_handle_menu_click", host_row.get_center())
	# host_row 不在 join 屏文字按钮上（最多命中输入框），应无状态切换
	_check(main.get("menu_mode") == "join", "click outside join hint buttons is ignored")
	var jareas: Array = main.call("_menu_action_areas")
	var connect_rect := Rect2()
	var back_rect := Rect2()
	var focus_rect := Rect2()
	for a in jareas:
		match a["action"]:
			"join_connect":
				connect_rect = a["rect"]
			"join_back":
				back_rect = a["rect"]
			"join_focus":
				focus_rect = a["rect"]
	# 命中区域按文字像素范围生成：CONNECT 在左、BACK 在右且互不重叠
	_check(connect_rect.size.x > 0.0 and back_rect.size.x > 0.0, "join hint areas exist")
	_check(connect_rect.end.x < back_rect.position.x, "CONNECT/BACK hit areas do not overlap")
	var hint_y: float = main.call("_input_hint_baseline_y")
	_check(connect_rect.has_point(Vector2(connect_rect.get_center().x, hint_y)), "CONNECT area covers its text baseline")
	_check(back_rect.has_point(Vector2(back_rect.get_center().x, hint_y)), "BACK area covers its text baseline")
	# 输入框命中区域与绘制框一致（仅外扩 2px）
	var ibox: Rect2 = main.call("_text_field_geometry")["box"]
	_check(absf(focus_rect.position.x - (ibox.position.x - 2.0)) < 0.01 and absf(focus_rect.end.y - (ibox.end.y + 2.0)) < 0.01, "input focus area hugs drawn box")
	# 输入文字基线垂直居中（旧版偏上：基线直接等于 input_y）
	var tbase: float = main.call("_text_field_geometry")["text_baseline"]
	_check(tbase > ibox.get_center().y and tbase < ibox.end.y - 8.0, "input text baseline is vertically centered in box")
	main.call("_handle_menu_click", connect_rect.get_center())
	_check(main.get("menu_mode") == "wait_join", "click CONNECT enters wait_join")

	# —— 失败后点击 BACK 返回主菜单 ——
	main.set("net_state", "failed")
	var warrays: Array = main.call("_menu_action_areas")
	for a in warrays:
		if a["action"] == "wait_back":
			main.call("_handle_menu_click", (a["rect"] as Rect2).get_center())
	_check(main.get("menu_mode") == "main", "click BACK on failed wait screen returns to main menu")

func _cleanup(code: int) -> void:
	if main != null:
		root.remove_child(main)
		main.queue_free()
		main = null
	print("UI TEST ", "OK" if fails.is_empty() else ("FAILED x%d" % fails.size()))
	quit(code)
