extends StaticBody3D
var health := 100.0
var max_health := 100.0
var bound_time := 0.0
var visual_root: Node3D
var health_fill: MeshInstance3D
func _ready() -> void:
	collision_layer = 2
	_build_dummy()
func _process(delta: float) -> void:
	if bound_time > 0.0: bound_time -= delta; visual_root.rotation.y += delta * 0.5
func take_damage(amount: float, spell: String, _impact: Vector3) -> void:
	health = max(health - amount, 0.0)
	if spell == "shadow": bound_time = 2.5
	if health_fill: health_fill.scale.x = max(health / max_health, 0.01)
	var tween := create_tween(); tween.tween_property(visual_root, "scale", Vector3(1.1, 0.9, 1.1), 0.06); tween.tween_property(visual_root, "scale", Vector3.ONE, 0.12)
	if health <= 0.0:
		set_deferred("collision_layer", 0)
		var respawn := create_tween(); respawn.tween_property(visual_root, "scale", Vector3.ZERO, 0.3); respawn.tween_interval(1.0); respawn.tween_callback(_reset)
func _reset() -> void:
	health = max_health; health_fill.scale = Vector3.ONE; visual_root.scale = Vector3.ONE; collision_layer = 2
func _build_dummy() -> void:
	visual_root = Node3D.new(); visual_root.name = "DummyVisual"; add_child(visual_root)
	var wood := _mat(Color("7d4a2d")); var straw := _mat(Color("d7a64f")); var red := _mat(Color("a83c4a"))
	_add_cylinder(0.12, 2.2, Vector3(0, 1.1, 0), wood)
	_add_box(Vector3(1.45, 0.14, 0.14), Vector3(0, 1.55, 0), wood)
	_add_cylinder(0.38, 0.8, Vector3(0, 1.15, 0), straw)
	_add_sphere(0.33, Vector3(0, 1.86, 0), straw)
	_add_box(Vector3(0.9, 0.16, 0.7), Vector3(0, 0.08, 0), wood)
	var target := _add_cylinder(0.24, 0.06, Vector3(0, 1.2, -0.39), red); target.rotation.x = PI * 0.5
	var collider := CollisionShape3D.new(); var shape := CapsuleShape3D.new(); shape.radius = 0.42; shape.height = 2.1; collider.shape = shape; collider.position.y = 1.1; add_child(collider)
	health_fill = _add_box(Vector3(1.0, 0.055, 0.05), Vector3(0, 2.45, -0.03), _mat(Color("73d47c")))
func _add_box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new(); mesh.size = size; return _mesh(mesh, pos, mat)
func _add_sphere(radius: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new(); mesh.radius = radius; mesh.height = radius * 2.0; mesh.radial_segments = 10; mesh.rings = 5; return _mesh(mesh, pos, mat)
func _add_cylinder(radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new(); mesh.top_radius = radius; mesh.bottom_radius = radius; mesh.height = height; mesh.radial_segments = 8; return _mesh(mesh, pos, mat)
func _mesh(mesh: PrimitiveMesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new(); item.mesh = mesh; item.position = pos; item.material_override = mat; visual_root.add_child(item); return item
func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; mat.roughness = 0.88; return mat
