extends Node3D

const SamHeart = preload("res://scripts/sam_heart.gd")
const SpellProjectile = preload("res://scripts/spell_projectile.gd")
const TrainingTarget = preload("res://scripts/training_target.gd")

const SPELL_LABELS := ["1 FUEGO", "2 AGUA", "3 AIRE", "4 TIERRA", "5 LUZ", "6 OSCURIDAD"]
const SPELL_COLORS := [
	Color("ef633c"), Color("3eb9e8"), Color("b9e7df"),
	Color("9a784b"), Color("f1df8c"), Color("7851a9")
]

var player: CharacterBody3D
var spell_cells: Array[PanelContainer] = []
var health_bar: ProgressBar
var mana_bar: ProgressBar
var selected_label: Label
var message_label: Label

func _ready() -> void:
	_build_environment()
	_build_arena()
	_spawn_player()
	_spawn_targets()
	_build_hud()

func _spawn_player() -> void:
	player = SamHeart.new()
	player.name = "SamHeart"
	player.position = Vector3(0, 0.05, 5.5)
	add_child(player)
	player.spell_cast_requested.connect(_on_spell_cast)
	player.selection_changed.connect(_on_selection_changed)
	player.resources_changed.connect(_on_resources_changed)

func _on_spell_cast(spell: String, origin: Vector3, direction: Vector3) -> void:
	match spell:
		"air":
			_spawn_ring(player.global_position + Vector3.UP * 0.9, Color("b9e7df"), 1.7)
			_show_message("Impulso de aire")
		"earth":
			_spawn_earth_wall(direction)
			_show_message("Muro de tierra")
		_:
			var projectile := SpellProjectile.new()
			projectile.name = "%sProjectile" % spell.capitalize()
			add_child(projectile)
			projectile.global_position = origin
			projectile.setup(spell, direction)
			projectile.impacted.connect(_on_projectile_impact)
			_show_message(_spell_display_name(spell))

func _on_projectile_impact(impact_position: Vector3, spell: String) -> void:
	var color: Color = {
		"fire": Color("ff6a38"), "water": Color("43c6ff"), "ice": Color("a8edff"),
		"light": Color("fff3a6"), "shadow": Color("8c5ad6"), "entei": Color("ff3c18")
	}.get(spell, Color.WHITE)
	_spawn_burst(impact_position, color)
	if spell == "entei":
		_spawn_ring(impact_position, color, 3.8)
		_spawn_burst(impact_position + Vector3.UP * 0.6, Color("ffb13b"))

func _spawn_earth_wall(direction: Vector3) -> void:
	var flat_direction := Vector3(direction.x, 0, direction.z).normalized()
	var wall := StaticBody3D.new()
	wall.name = "EarthWall"
	wall.position = player.global_position + flat_direction * 2.4 + Vector3.UP * 1.0
	wall.rotation.y = atan2(flat_direction.x, flat_direction.z)
	add_child(wall)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.9, 2.0, 0.48)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(Color("79583b"), 0.95)
	wall.add_child(mesh_instance)

	for x in [-1.15, -0.55, 0.0, 0.55, 1.15]:
		var stone := MeshInstance3D.new()
		var stone_mesh := SphereMesh.new()
		stone_mesh.radius = 0.28
		stone_mesh.height = 0.56
		stone_mesh.radial_segments = 7
		stone_mesh.rings = 3
		stone.mesh = stone_mesh
		stone.position = Vector3(x, 0.82 + abs(x) * 0.08, -0.03)
		stone.scale = Vector3(1.2, 0.8, 0.7)
		stone.material_override = _material(Color("a17c52"), 1.0)
		wall.add_child(stone)

	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.9, 2.0, 0.48)
	collider.shape = shape
	wall.add_child(collider)

	wall.scale = Vector3(1, 0.02, 1)
	var tween := create_tween()
	tween.tween_property(wall, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(4.5)
	tween.tween_property(wall, "scale", Vector3(1, 0.02, 1), 0.3)
	tween.tween_callback(wall.queue_free)

func _spawn_burst(pos: Vector3, color: Color) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	for i in 10:
		var shard := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.07 + (i % 3) * 0.025
		mesh.height = mesh.radius * 2.0
		mesh.radial_segments = 6
		mesh.rings = 3
		shard.mesh = mesh
		shard.material_override = _glow_material(color, 2.5)
		root.add_child(shard)
		var angle := TAU * float(i) / 10.0
		var destination := Vector3(cos(angle), 0.25 + (i % 2) * 0.5, sin(angle)) * (0.7 + (i % 3) * 0.18)
		var shard_tween := create_tween()
		shard_tween.set_parallel(true)
		shard_tween.tween_property(shard, "position", destination, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		shard_tween.tween_property(shard, "scale", Vector3.ZERO, 0.4).set_delay(0.12)
	get_tree().create_timer(0.6).timeout.connect(root.queue_free)

func _spawn_ring(pos: Vector3, color: Color, final_scale: float) -> void:
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.42
	mesh.outer_radius = 0.49
	mesh.rings = 8
	mesh.ring_segments = 16
	ring.mesh = mesh
	ring.position = pos
	ring.rotation.x = PI * 0.5
	ring.scale = Vector3.ONE * 0.2
	ring.material_override = _glow_material(color, 2.0)
	add_child(ring)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * final_scale, 0.35)
	tween.tween_property(ring, "position:y", pos.y + 0.35, 0.35)
	tween.chain().tween_callback(ring.queue_free)

func _build_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("161425")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8a7fb0")
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.85
	environment_node.environment = environment
	add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.name = "MoonKeyLight"
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_color = Color("fff0db")
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-4, 5, 4)
	fill.light_color = Color("a47eea")
	fill.light_energy = 5.0
	fill.omni_range = 12.0
	add_child(fill)

func _build_arena() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "ArenaFloor"
	add_child(floor_body)
	var floor_mesh_instance := MeshInstance3D.new()
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 13.5
	floor_mesh.bottom_radius = 13.8
	floor_mesh.height = 0.35
	floor_mesh.radial_segments = 32
	floor_mesh_instance.mesh = floor_mesh
	floor_mesh_instance.position.y = -0.18
	floor_mesh_instance.material_override = _material(Color("29233a"), 0.9)
	floor_body.add_child(floor_mesh_instance)
	var floor_shape := CollisionShape3D.new()
	var cylinder_shape := CylinderShape3D.new()
	cylinder_shape.radius = 13.5
	cylinder_shape.height = 0.35
	floor_shape.shape = cylinder_shape
	floor_shape.position.y = -0.18
	floor_body.add_child(floor_shape)

	for radius in [4.0, 8.0, 12.0]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius - 0.035
		torus.outer_radius = radius + 0.035
		torus.rings = 8
		torus.ring_segments = 64
		ring.mesh = torus
		ring.position.y = 0.015
		ring.material_override = _glow_material(Color("7755ad"), 1.7)
		add_child(ring)

	for i in 8:
		var angle := TAU * float(i) / 8.0
		var pillar := MeshInstance3D.new()
		var pillar_mesh := CylinderMesh.new()
		pillar_mesh.top_radius = 0.38
		pillar_mesh.bottom_radius = 0.58
		pillar_mesh.height = 3.0
		pillar_mesh.radial_segments = 6
		pillar.mesh = pillar_mesh
		pillar.position = Vector3(cos(angle) * 11.5, 1.5, sin(angle) * 11.5)
		pillar.material_override = _material(Color("443759"), 0.92)
		add_child(pillar)
		var crystal := MeshInstance3D.new()
		var crystal_mesh := PrismMesh.new()
		crystal_mesh.size = Vector3(0.45, 0.8, 0.45)
		crystal.mesh = crystal_mesh
		crystal.position = pillar.position + Vector3.UP * 1.9
		crystal.rotation.y = angle
		crystal.material_override = _glow_material(Color("a56cff"), 2.8)
		add_child(crystal)

func _spawn_targets() -> void:
	var target_positions := [Vector3(0, 0, -6), Vector3(-5, 0, -3), Vector3(5, 0, -3), Vector3(0, 0, -10)]
	for i in target_positions.size():
		var target := TrainingTarget.new()
		target.name = "TrainingTarget%d" % (i + 1)
		target.position = target_positions[i]
		add_child(target)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)

	var title := Label.new()
	title.text = "MAGIA: DESPERTAR"
	title.position = Vector2(28, 22)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("e6d6ff"))
	root.add_child(title)

	var status := VBoxContainer.new()
	status.position = Vector2(28, 58)
	status.size = Vector2(250, 90)
	root.add_child(status)
	health_bar = _status_bar("VIDA", Color("d95362"), status)
	mana_bar = _status_bar("MANA", Color("8d64d6"), status)

	selected_label = Label.new()
	selected_label.text = "Fuego"
	selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	selected_label.position = Vector2(-90, 24)
	selected_label.size = Vector2(180, 32)
	selected_label.add_theme_font_size_override("font_size", 18)
	selected_label.add_theme_color_override("font_color", Color("f2e9ff"))
	root.add_child(selected_label)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8, -18)
	crosshair.size = Vector2(16, 36)
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.add_theme_font_size_override("font_size", 25)
	crosshair.add_theme_color_override("font_color", Color("f6efff"))
	root.add_child(crosshair)

	var spell_bar := HBoxContainer.new()
	spell_bar.name = "SpellBar"
	spell_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	spell_bar.position = Vector2(-348, -82)
	spell_bar.size = Vector2(696, 58)
	spell_bar.add_theme_constant_override("separation", 8)
	root.add_child(spell_bar)

	for i in SPELL_LABELS.size():
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(108, 54)
		panel.tooltip_text = "Selecciona con %d" % (i + 1)
		var label := Label.new()
		label.text = SPELL_LABELS[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		panel.add_child(label)
		spell_bar.add_child(panel)
		spell_cells.append(panel)

	message_label = Label.new()
	message_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	message_label.position = Vector2(-180, -126)
	message_label.size = Vector2(360, 34)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.modulate.a = 0.0
	root.add_child(message_label)

	var controls := Label.new()
	controls.text = "WASD mover   SHIFT correr   ESPACIO saltar   CLIC/Q lanzar   CLIC DER hielo/Entei   ESC raton"
	controls.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	controls.position = Vector2(24, -34)
	controls.add_theme_font_size_override("font_size", 12)
	controls.add_theme_color_override("font_color", Color("bdb5ca"))
	root.add_child(controls)

	_on_selection_changed(0, "Fuego")
	_on_resources_changed(100.0, 100.0)

func _status_bar(label_text: String, color: Color, parent: VBoxContainer) -> ProgressBar:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 48
	label.add_theme_font_size_override("font_size", 12)
	row.add_child(label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(180, 16)
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	return bar

func _on_selection_changed(index: int, spell_name: String) -> void:
	if not selected_label:
		return
	selected_label.text = spell_name
	selected_label.add_theme_color_override("font_color", SPELL_COLORS[index])
	for i in spell_cells.size():
		var style := StyleBoxFlat.new()
		style.bg_color = Color(SPELL_COLORS[i], 0.62 if i == index else 0.18)
		style.border_color = SPELL_COLORS[i] if i == index else Color("554e64")
		style.set_border_width_all(2 if i == index else 1)
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
		spell_cells[i].add_theme_stylebox_override("panel", style)

func _on_resources_changed(health: float, mana: float) -> void:
	if health_bar:
		health_bar.value = health
	if mana_bar:
		mana_bar.value = mana

func _show_message(text: String) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.65)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.3)

func _spell_display_name(spell: String) -> String:
	return {
		"fire": "Bola de fuego", "water": "Corriente de agua", "ice": "Proyectil de hielo",
		"light": "Orbe de luz", "shadow": "Atadura de sombra", "entei": "Explosion de Fuego: Entei"
	}.get(spell, spell.capitalize())

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _material(color, 0.25)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
