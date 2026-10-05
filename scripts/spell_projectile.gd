extends Area3D
signal impacted(position: Vector3, spell: String)
var spell := "fire"
var direction := Vector3.FORWARD
var speed := 14.0
var damage := 20.0
var lifetime := 3.0
var visual: MeshInstance3D
var aura: MeshInstance3D
const COLORS := {"fire": Color("ff6a38"), "water": Color("43c6ff"), "ice": Color("a8edff"), "light": Color("fff3a6"), "shadow": Color("8c5ad6"), "entei": Color("ff3c18")}
func setup(kind: String, cast_direction: Vector3) -> void:
	spell = kind
	direction = cast_direction.normalized()
	collision_layer = 0
	collision_mask = 2
	match spell:
		"water": speed = 20.0; damage = 10.0; lifetime = 2.2
		"ice": speed = 17.0; damage = 24.0
		"light": speed = 9.0; damage = 17.0; lifetime = 4.0
		"shadow": speed = 12.0; damage = 12.0; lifetime = 3.5
		"entei": speed = 10.0; damage = 65.0; lifetime = 4.0
	_build_visual()
	body_entered.connect(_on_body_entered)
func _build_visual() -> void:
	var color: Color = COLORS.get(spell, Color.WHITE)
	visual = MeshInstance3D.new()
	if spell == "ice":
		var prism := PrismMesh.new(); prism.size = Vector3(0.25, 0.25, 0.8); visual.mesh = prism
	elif spell == "water":
		var capsule := CapsuleMesh.new(); capsule.radius = 0.12; capsule.height = 0.7; capsule.radial_segments = 8; capsule.rings = 3; visual.mesh = capsule
	else:
		var sphere := SphereMesh.new(); sphere.radius = 0.62 if spell == "entei" else (0.28 if spell == "light" else 0.19); sphere.height = sphere.radius * 2.0; sphere.radial_segments = 10; sphere.rings = 5; visual.mesh = sphere
	visual.material_override = _glow_material(color, 3.5)
	add_child(visual)
	aura = MeshInstance3D.new()
	var aura_mesh := SphereMesh.new(); aura_mesh.radius = 0.9 if spell == "entei" else (0.43 if spell == "light" else 0.3); aura_mesh.height = aura_mesh.radius * 2.0; aura_mesh.radial_segments = 8; aura_mesh.rings = 4; aura.mesh = aura_mesh; aura.material_override = _glow_material(Color(color, 0.2), 1.8, true); add_child(aura)
	var shape := CollisionShape3D.new(); var sphere_shape := SphereShape3D.new(); sphere_shape.radius = 0.72 if spell == "entei" else 0.3; shape.shape = sphere_shape; add_child(shape)
	var light := OmniLight3D.new(); light.light_color = color; light.light_energy = 6.0 if spell == "entei" else 2.2; light.omni_range = 8.0 if spell == "entei" else 3.5; add_child(light)
func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0: queue_free(); return
	global_position += direction * speed * delta
	visual.rotate_y(delta * 7.0)
	aura.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.012) * 0.12)
func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"): body.take_damage(damage, spell, global_position)
	impacted.emit(global_position, spell)
	queue_free()
func _glow_material(color: Color, energy: float, transparent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = 0.25; material.emission_enabled = true; material.emission = color; material.emission_energy_multiplier = energy
	if transparent: material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
