extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var game := load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	assert(game.player != null)
	assert(game.player.camera != null and game.player.wand_tip != null)
	var origin := game.player.global_position + Vector3(0, 1.5, -0.8)
	for spell in ["fire", "water", "air", "earth", "light", "shadow", "ice", "entei"]:
		game._on_spell_cast(spell, origin, Vector3.FORWARD)
	var target = game.get_node("TrainingTarget1")
	var before: float = target.health
	target.take_damage(10.0, "shadow", target.global_position)
	assert(target.health == before - 10.0)
	assert(target.bound_time > 0.0)
	print("SMOKE_TEST_OK")
	quit(0)
