extends CharacterBody3D

signal spell_cast_requested(spell: String, origin: Vector3, direction: Vector3)
signal selection_changed(index: int, spell: String)
signal resources_changed(health: float, mana: float)

const SPELLS: Array[String] = ["fire", "water", "air", "earth", "light", "shadow"]
const NAMES: Array[String] = ["Fuego", "Agua", "Aire", "Tierra", "Luz", "Oscuridad"]
const COSTS: Array[float] = [14.0, 9.0, 18.0, 22.0, 20.0, 24.0]
var health := 100.0
var mana := 100.0
var selected_spell := 0
var cooldown := 0.0
var dash_time := 0.0
var visual_root: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var wand_tip: Marker3D
var camera_yaw: Node3D
var camera_pitch: Node3D
var camera: Camera3D
var mats := {}
var walk_phase := 0.0

func _ready() -> void:
	_build_mats()
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 2.55
	collider.shape = capsule
	collider.position.y = 1.28
	add_child(collider)
	_build_visual()
	_build_camera()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	selection_changed.emit(0, NAMES[0])
	resources_changed.emit(health, mana)

func _physics_process(delta: float) -> void:
	cooldown = max(cooldown - delta, 0.0)
	mana = min(mana + delta * 7.5, 100.0)
	if not is_on_floor(): velocity.y -= 19.0 * delta
	elif Input.is_physical_key_pressed(KEY_SPACE): velocity.y = 7.0
	var input := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A): input.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D): input.x += 1.0
	if Input.is_physical_key_pressed(KEY_W): input.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S): input.y += 1.0
	input = input.normalized()
	var forward := -camera_yaw.global_transform.basis.z
	var right := camera_yaw.global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	var direction := (right * input.x + forward * -input.y).normalized()
	var speed := 7.3 if Input.is_physical_key_pressed(KEY_SHIFT) else 5.2
	if dash_time > 0.0:
		dash_time -= delta
		var dash := direction if direction.length_squared() > 0.01 else -transform.basis.z
		velocity.x = dash.x * 14.0
		velocity.z = dash.z * 14.0
	else:
		velocity.x = move_toward(velocity.x, direction.x * speed, 24.0 * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, 24.0 * delta)
	if direction.length_squared() > 0.01: rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 10.0)
	move_and_slide()
	camera_yaw.global_position = global_position + Vector3.UP * 1.75
	var moving := Vector2(velocity.x, velocity.z).length()
	if moving > 0.25 and is_on_floor():
		walk_phase += delta * 9.0
		var swing := sin(walk_phase) * 0.55
		left_leg.rotation.x = swing
		right_leg.rotation.x = -swing
		left_arm.rotation.x = -swing * 0.5
		right_arm.rotation.x = swing * 0.3
		visual_root.position.y = sin(walk_phase * 2.0) * 0.025
	else:
		left_leg.rotation.x = lerp(left_leg.rotation.x, 0.0, delta * 8.0)
		right_leg.rotation.x = lerp(right_leg.rotation.x, 0.0, delta * 8.0)
		visual_root.position.y = sin(Time.get_ticks_msec() * 0.002) * 0.012
	resources_changed.emit(health, mana)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_yaw.rotation.y -= event.relative.x * 0.0025
		camera_pitch.rotation.x = clamp(camera_pitch.rotation.x - event.relative.y * 0.0025, deg_to_rad(-52), deg_to_rad(24))
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT: _cast()
		elif event.button_index == MOUSE_BUTTON_RIGHT: _variant()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP: _select(posmod(selected_spell - 1, 6))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _select(posmod(selected_spell + 1, 6))
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_6: _select(event.keycode - KEY_1)
		elif event.keycode == KEY_Q: _cast()
		elif event.keycode == KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _select(index: int) -> void:
	selected_spell = clamp(index, 0, 5)
	selection_changed.emit(selected_spell, NAMES[selected_spell])

func _cast() -> void:
	if cooldown > 0.0 or mana < COSTS[selected_spell]: return
	var spell: String = SPELLS[selected_spell]
	mana -= COSTS[selected_spell]
	cooldown = 0.32 if spell == "water" else 0.55
	if spell == "air": dash_time = 0.22
	spell_cast_requested.emit(spell, wand_tip.global_position, -camera.global_transform.basis.z.normalized())
	_flash_arm()

func _variant() -> void:
	if cooldown > 0.0: return
	if selected_spell == 0 and mana >= 45.0:
		mana -= 45.0
		cooldown = 1.15
		spell_cast_requested.emit("entei", wand_tip.global_position, -camera.global_transform.basis.z.normalized())
	elif selected_spell == 1 and mana >= 18.0:
		mana -= 18.0
		cooldown = 0.7
		spell_cast_requested.emit("ice", wand_tip.global_position, -camera.global_transform.basis.z.normalized())
	else: _cast()
	_flash_arm()

func _flash_arm() -> void:
	var tween := create_tween()
	tween.tween_property(right_arm, "rotation:x", -1.2, 0.09)
	tween.tween_property(right_arm, "rotation:x", 0.08, 0.22).set_trans(Tween.TRANS_BACK)

func _build_camera() -> void:
	camera_yaw = Node3D.new()
	camera_yaw.top_level = true
	camera_yaw.global_position = global_position + Vector3.UP * 1.75
	add_child(camera_yaw)
	camera_pitch = Node3D.new()
	camera_pitch.rotation.x = deg_to_rad(-12)
	camera_yaw.add_child(camera_pitch)
	var boom := SpringArm3D.new()
	boom.spring_length = 5.2
	boom.margin = 0.2
	camera_pitch.add_child(boom)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 60.0
	boom.add_child(camera)

func _build_mats() -> void:
	mats = {"skin": _mat(Color("f3c2a5")), "skin2": _mat(Color("d99d82")), "hair": _mat(Color("9a5738")), "hair2": _mat(Color("bd7048")), "purple": _mat(Color("65408f")), "lilac": _mat(Color("c5a8dc")), "dark": _mat(Color("30263e")), "leather": _mat(Color("6b402e")), "leather2": _mat(Color("9b6341")), "gold": _mat(Color("d7a356"), 0.45), "eye": _mat(Color("476b45")), "white": _mat(Color("f5eee8")), "black": _mat(Color("17131a")), "crystal": _glow(Color("bf7cff"), 3.8)}

func _build_visual() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	left_leg = _limb("LeftLeg", -0.23)
	right_leg = _limb("RightLeg", 0.23)
	_part("Robe", _cyl(0.56, 0.82, 0.98), Vector3(0, 1.25, 0), mats.purple)
	_part("Front", _box(Vector3(0.48, 0.82, 0.06)), Vector3(0, 1.22, -0.38), mats.lilac)
	_part("Trim", _box(Vector3(0.9, 0.05, 0.04)), Vector3(0, 0.83, -0.42), mats.gold)
	_part("Torso", _cyl(0.31, 0.38, 0.73), Vector3(0, 1.78, 0), mats.purple)
	_part("Blouse", _box(Vector3(0.34, 0.54, 0.04)), Vector3(0, 1.82, -0.34), mats.lilac)
	_part("Belt", _box(Vector3(0.82, 0.18, 0.47)), Vector3(0, 1.49, 0), mats.leather)
	_part("Buckle", _box(Vector3(0.18, 0.18, 0.06)), Vector3(0, 1.49, -0.27), mats.gold)
	left_arm = _arm(-0.52, false)
	right_arm = _arm(0.52, true)
	var head := Node3D.new()
	head.position = Vector3(0, 2.39, -0.02)
	visual_root.add_child(head)
	_part("Face", _sphere(0.38), Vector3.ZERO, Vector3(0.92, 1.08, 0.9), mats.skin, head)
	_part("HairCap", _sphere(0.43), Vector3(0, 0.15, 0.03), Vector3(1.03, 0.9, 0.95), mats.hair, head)
	_part("HairBack", _sphere(0.43), Vector3(0, -0.05, 0.3), Vector3(1.0, 1.1, 0.55), mats.hair, head)
	for x in [-0.14, 0.14]:
		_part("Eye", _sphere(0.105), Vector3(x, 0.075, -0.34), Vector3(0.88, 1.12, 0.38), mats.white, head)
		_part("Iris", _sphere(0.058), Vector3(x, 0.075, -0.385), Vector3(0.9, 1.08, 0.32), mats.eye, head)
	for x in [-0.28, -0.14, 0.0, 0.14, 0.28]:
		var lock := _part("HairLock", _cyl(0.07, 0.11, 0.38), Vector3(x, 0.28 - abs(x) * 0.3, -0.31), mats.hair2, head)
		lock.rotation.z = x * 1.6
	var pony := Node3D.new()
	pony.position = Vector3(0, 0.05, 0.38)
	head.add_child(pony)
	_part("Ribbon", _box(Vector3(0.38, 0.11, 0.12)), Vector3.ZERO, mats.lilac, pony)
	for i in 4:
		var strand := _part("Pony", _caps(0.13, 0.7), Vector3((i - 1.5) * 0.12, -0.35, 0.05), mats.hair if i % 2 == 0 else mats.hair2, pony)
		strand.rotation.z = (i - 1.5) * 0.25
	var book := Node3D.new()
	book.position = Vector3(-0.56, 1.26, 0.02)
	visual_root.add_child(book)
	_part("BookPages", _box(Vector3(0.38, 0.58, 0.16)), Vector3.ZERO, mats.white, book)
	_part("BookCover", _box(Vector3(0.44, 0.64, 0.055)), Vector3(0, 0, -0.11), mats.leather, book)

func _limb(n: String, x: float) -> Node3D:
	var root := Node3D.new()
	root.name = n
	root.position = Vector3(x, 1.15, 0)
	visual_root.add_child(root)
	_part("Leg", _cyl(0.14, 0.16, 0.75), Vector3(0, -0.34, 0), mats.dark, root)
	_part("Boot", _cyl(0.17, 0.21, 0.65), Vector3(0, -0.82, -0.04), mats.leather, root)
	_part("Sole", _box(Vector3(0.4, 0.08, 0.57)), Vector3(0, -1.15, -0.1), mats.dark, root)
	return root

func _arm(x: float, wand: bool) -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(x, 1.98, 0)
	visual_root.add_child(root)
	_part("Sleeve", _cyl(0.18, 0.3, 0.88), Vector3(0, -0.48, 0), mats.purple, root)
	_part("Hand", _sphere(0.14), Vector3(0, -0.98, 0), Vector3(0.82, 1.15, 0.75), mats.skin, root)
	if wand:
		var staff := Node3D.new()
		staff.position = Vector3(0, -1.0, -0.03)
		staff.rotation.x = -0.18
		root.add_child(staff)
		_part("Wood", _cyl(0.035, 0.045, 0.95), Vector3(0, -0.08, 0), mats.leather, staff)
		_part("Crystal", _sphere(0.16), Vector3(0, 0.52, 0), Vector3(0.8, 1.5, 0.8), mats.crystal, staff)
		wand_tip = Marker3D.new()
		wand_tip.position = Vector3(0, 0.75, 0)
		staff.add_child(wand_tip)
	return root

func _part(n, mesh, pos, a, b = null, c = Vector3.ONE) -> MeshInstance3D:
	var material: Material = null
	var parent: Node3D = null
	var scale := Vector3.ONE
	if a is Material:
		material = a
		if b is Node3D: parent = b
		if c is Vector3: scale = c
	else:
		scale = a
		if b is Material: material = b
		elif b is Node3D: parent = b
		if c is Material: material = c
	var item := MeshInstance3D.new()
	item.name = n
	item.mesh = mesh
	item.position = pos
	item.scale = scale
	item.material_override = material
	(parent if parent else visual_root).add_child(item)
	return item

func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m
func _sphere(r: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 10
	m.rings = 5
	return m
func _cyl(top: float, bottom: float, height: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = 8
	return m
func _caps(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 8
	m.rings = 4
	return m
func _mat(c: Color, rough := 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m
func _glow(c: Color, e: float) -> StandardMaterial3D:
	var m := _mat(c, 0.2)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	return m
