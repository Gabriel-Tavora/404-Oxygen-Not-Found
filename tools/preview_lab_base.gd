extends SceneTree
## Captura a cena no renderizador do Godot, sem modificar a fase.


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	root.content_scale_size = Vector2i(480, 288)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
	root.size = Vector2i(1440, 864)
	var scene := load("res://scenes/lab-fisica/lab-fisica.tscn") as PackedScene
	root.add_child(scene.instantiate())
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var prefix := "lab-fisica"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--name="):
			prefix = argument.trim_prefix("--name=").get_file().get_basename()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	image.save_png("res://artifacts/" + prefix + ".png")
	image.resize(1440, 864, Image.INTERPOLATE_NEAREST)
	image.save_png("res://artifacts/" + prefix + "-3x.png")
	print("Prévia da cena salva em artifacts/", prefix, "-3x.png")
	quit()
