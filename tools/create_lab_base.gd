extends SceneTree
## Construtor da primeira seção: somente piso, paredes e vigas.
## Os pixels são pintados diretamente em uma imagem raster, sem antialiasing.

const TILE := 16
const ASSET_DIR := "res://assets/lab-fisica"
const ATLAS_PATH := ASSET_DIR + "/lab-fisica-tiles.png"
const TILESET_PATH := ASSET_DIR + "/lab-fisica-tiles.tres"
const SCENE_PATH := "res://scenes/lab-fisica/base-lab-fisica.tscn"
const OUTLINE := Color("293b43")
const WOOD_DARK := Color("4e4840")
const WOOD_SHADE := Color("78604b")
const WOOD := Color("a98057")
const WOOD_LIGHT := Color("c9a16d")
const WOOD_GLEAM := Color("e4c28c")
const PLASTER_SHADE := Color("72999a")
const PLASTER := Color("93b7af")
const PLASTER_LIGHT := Color("b5cbb8")
const PANEL_DARK := Color("334f56")
const PANEL_SHADE := Color("436e73")
const PANEL := Color("588b88")
const PANEL_LIGHT := Color("7ba49a")
const FLOOR_DARK := Color("81634f")
const FLOOR_SHADE := Color("a57b57")
const FLOOR := Color("bb9365")
const FLOOR_LIGHT := Color("caa676")
const FLOOR_GLEAM := Color("d9b988")

var atlas: Image


func _initialize() -> void:
	if "--texture-only" in OS.get_cmdline_user_args():
		_create_atlas()
		quit()
		return
	_build_scene()
	quit()


func _paint(index: int, x: int, y: int, width: int, height: int, color: Color) -> void:
	var origin := _coord(index) * TILE
	atlas.fill_rect(Rect2i(origin + Vector2i(x, y), Vector2i(width, height)), color)


func _coord(index: int) -> Vector2i:
	return Vector2i(index % 8, floori(float(index) / 8.0))


func _create_atlas() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ASSET_DIR))
	atlas = Image.create(128, 64, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for index in range(8):
		_floor_tile(index)
	_plaster_tile(8)
	_plaster_tile(9)
	_paint(9, 10, 9, 3, 1, PLASTER_LIGHT)
	_paint(9, 12, 8, 2, 1, PLASTER_LIGHT)
	_plaster_tile(10)
	_paint(10, 3, 3, 4, 1, PLASTER_SHADE)
	_paint(10, 3, 4, 2, 1, PLASTER_SHADE)
	_plaster_tile(11)
	_paint(11, 14, 0, 1, 16, PLASTER_SHADE)
	_paint(11, 15, 0, 1, 16, PLASTER_LIGHT)
	_wainscot_tile(12)
	_skirt_tile(13)
	_top_beam(14)
	_front_beam(15)
	_side_post(16, false)
	_side_post(17, true)
	_top_corner(18, false)
	_top_corner(19, true)
	_front_corner(20, false)
	_front_corner(21, true)
	for index in range(22, 24):
		_floor_tile(index, index - 22)
		_paint(index, 0, 0, 16, 2, WOOD_DARK)
		_paint(index, 0, 2, 16, 2, FLOOR_DARK)
		_paint(index, 0, 4, 16, 2, FLOOR_SHADE)
	_floor_tile(24, 0)
	_paint(24, 0, 0, 2, 16, WOOD_DARK)
	_paint(24, 2, 0, 2, 16, FLOOR_DARK)
	_floor_tile(25, 1)
	_paint(25, 14, 0, 2, 16, WOOD_DARK)
	_paint(25, 12, 0, 2, 16, FLOOR_DARK)
	_rear_post(26)
	_rear_post(27)
	_paint(27, 2, 10, 12, 1, OUTLINE)
	_paint(27, 2, 11, 12, 3, WOOD)
	_paint(27, 3, 11, 9, 1, WOOD_GLEAM)
	_floor_tile(28, 0)
	_paint(28, 0, 0, 16, 6, FLOOR_DARK)
	_paint(28, 0, 0, 16, 3, WOOD_DARK)
	_paint(28, 0, 0, 4, 16, FLOOR_DARK)
	_paint(28, 0, 0, 2, 16, WOOD_DARK)
	_floor_tile(29, 1)
	_paint(29, 0, 0, 16, 6, FLOOR_DARK)
	_paint(29, 0, 0, 16, 3, WOOD_DARK)
	_paint(29, 12, 0, 4, 16, FLOOR_DARK)
	_paint(29, 14, 0, 2, 16, WOOD_DARK)
	# Sombras curtas sob as vigas, sempre com luz vindo do alto à esquerda.
	_floor_tile(30, 0)
	_paint(30, 4, 0, 10, 3, FLOOR_DARK)
	_paint(30, 6, 3, 8, 2, FLOOR_SHADE)
	_floor_tile(31, 1)
	_paint(31, 0, 13, 16, 2, FLOOR_SHADE)
	_paint(31, 0, 15, 16, 1, FLOOR_DARK)
	var error := atlas.save_png(ATLAS_PATH)
	if error != OK:
		push_error("Não foi possível salvar o atlas: %s" % error)
		quit(1)
	print("Atlas raster criado: ", ATLAS_PATH)


func _floor_tile(index: int, style: int = -1) -> void:
	var variant := index if style < 0 else style
	_paint(index, 0, 0, 16, 16, FLOOR)
	_paint(index, 0, 0, 16, 1, FLOOR_DARK)
	_paint(index, 0, 1, 16, 1, FLOOR_LIGHT)
	_paint(index, 0, 15, 16, 1, FLOOR_SHADE)
	# Uma emenda a cada 32 px; as fileiras seguintes deslocam a emenda.
	if variant % 2 == 0:
		_paint(index, 0, 1, 1, 15, FLOOR_SHADE)
		_paint(index, 1, 2, 1, 12, FLOOR_LIGHT)
	match variant:
		0, 1:
			_paint(index, 5, 6, 7, 1, FLOOR_LIGHT)
			_paint(index, 9, 7, 5, 1, FLOOR_LIGHT)
			_paint(index, 3, 12, 5, 1, FLOOR_SHADE)
		2, 3:
			_paint(index, 3, 4, 9, 1, FLOOR_LIGHT)
			_paint(index, 2, 11, 8, 1, FLOOR_LIGHT)
			_paint(index, 10, 10, 4, 1, FLOOR_SHADE)
		4, 5:
			_paint(index, 4, 9, 8, 1, FLOOR_LIGHT)
			_paint(index, 6, 10, 5, 1, FLOOR_LIGHT)
			_paint(index, 2, 4, 4, 1, FLOOR_SHADE)
		6, 7:
			_paint(index, 2, 5, 6, 1, FLOOR_LIGHT)
			_paint(index, 8, 12, 6, 1, FLOOR_LIGHT)
			_paint(index, 6, 8, 4, 1, FLOOR_SHADE)
			_paint(index, 7, 7, 2, 1, FLOOR_SHADE)
	# Pequenos grupos de pixels, sem ruído aleatório ou textura fotográfica.
	if variant == 6:
		_paint(index, 3, 2, 1, 1, FLOOR_DARK)
		_paint(index, 3, 13, 1, 1, FLOOR_DARK)


func _plaster_tile(index: int) -> void:
	_paint(index, 0, 0, 16, 16, PLASTER)


func _wainscot_tile(index: int) -> void:
	_paint(index, 0, 0, 16, 16, PANEL)
	_paint(index, 0, 0, 16, 1, PANEL_DARK)
	_paint(index, 0, 1, 16, 2, PANEL_LIGHT)
	_paint(index, 0, 3, 16, 2, PANEL_SHADE)
	_paint(index, 0, 5, 16, 1, PANEL_DARK)
	_paint(index, 0, 6, 1, 10, PANEL_SHADE)
	_paint(index, 1, 6, 1, 10, PANEL_LIGHT)
	_paint(index, 14, 6, 1, 10, PANEL_SHADE)
	_paint(index, 15, 6, 1, 10, PANEL_DARK)


func _skirt_tile(index: int) -> void:
	_paint(index, 0, 0, 16, 16, PANEL)
	_paint(index, 0, 0, 1, 9, PANEL_SHADE)
	_paint(index, 1, 0, 1, 9, PANEL_LIGHT)
	_paint(index, 14, 0, 1, 9, PANEL_SHADE)
	_paint(index, 15, 0, 1, 9, PANEL_DARK)
	_paint(index, 0, 9, 16, 1, PANEL_DARK)
	_paint(index, 0, 10, 16, 2, WOOD_LIGHT)
	_paint(index, 0, 12, 16, 2, WOOD)
	_paint(index, 0, 14, 16, 1, WOOD_SHADE)
	_paint(index, 0, 15, 16, 1, OUTLINE)


func _top_beam(index: int) -> void:
	_paint(index, 0, 0, 16, 16, OUTLINE)
	_paint(index, 0, 2, 16, 10, WOOD)
	_paint(index, 0, 2, 16, 2, WOOD_GLEAM)
	_paint(index, 0, 4, 16, 2, WOOD_LIGHT)
	_paint(index, 0, 10, 16, 2, WOOD_SHADE)
	_paint(index, 0, 13, 16, 3, PLASTER_SHADE)
	_paint(index, 3, 8, 6, 1, WOOD_LIGHT)


func _front_beam(index: int) -> void:
	_paint(index, 0, 0, 16, 16, OUTLINE)
	_paint(index, 0, 2, 16, 7, WOOD)
	_paint(index, 0, 2, 16, 2, WOOD_GLEAM)
	_paint(index, 0, 4, 16, 2, WOOD_LIGHT)
	_paint(index, 0, 9, 16, 5, WOOD_SHADE)
	_paint(index, 0, 10, 16, 1, WOOD)
	_paint(index, 3, 7, 7, 1, WOOD_LIGHT)


func _side_post(index: int, right: bool) -> void:
	_paint(index, 0, 0, 16, 16, OUTLINE)
	_paint(index, 2, 0, 10, 16, WOOD)
	_paint(index, 2, 0, 2, 16, WOOD_LIGHT)
	_paint(index, 10, 0, 2, 16, WOOD_SHADE)
	_paint(index, 5, 2, 1, 7, WOOD_LIGHT)
	_paint(index, 8, 11, 1, 5, WOOD_SHADE)
	if right:
		_paint(index, 0, 0, 2, 16, PANEL_DARK)
		_paint(index, 12, 0, 2, 16, WOOD_DARK)
	else:
		_paint(index, 12, 0, 2, 16, WOOD_DARK)
		_paint(index, 14, 0, 2, 16, PANEL_DARK)


func _top_corner(index: int, right: bool) -> void:
	_side_post(index, right)
	_paint(index, 2, 2, 12, 10, WOOD_LIGHT)
	_paint(index, 2, 2, 12, 2, WOOD_GLEAM)
	_paint(index, 12, 4, 2, 8, WOOD_SHADE)
	_paint(index, 5, 6, 2, 2, WOOD_DARK)
	_paint(index, 6, 6, 1, 1, WOOD_GLEAM)
	_paint(index, 2, 12, 12, 2, OUTLINE)


func _front_corner(index: int, right: bool) -> void:
	_front_beam(index)
	_paint(index, 0 if right else 14, 0, 2, 14, WOOD_DARK)
	_paint(index, 4, 5, 2, 2, WOOD_DARK)
	_paint(index, 4, 5, 1, 1, WOOD_GLEAM)


func _rear_post(index: int) -> void:
	_paint(index, 2, 0, 12, 16, PLASTER_SHADE)
	_paint(index, 2, 0, 9, 16, OUTLINE)
	_paint(index, 3, 0, 7, 16, WOOD)
	_paint(index, 3, 0, 2, 16, WOOD_LIGHT)
	_paint(index, 9, 0, 1, 16, WOOD_SHADE)
	_paint(index, 7, 3, 1, 8, WOOD_SHADE)


func _layer(parent: Node2D, label: String, tiles: TileSet, depth: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = label
	layer.tile_set = tiles
	layer.z_index = depth
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(layer)
	layer.owner = parent
	return layer


func _put(layer: TileMapLayer, x: int, y: int, index: int) -> void:
	layer.set_cell(Vector2i(x, y), 0, _coord(index))


func _build_scene() -> void:
	var texture := load(ATLAS_PATH) as Texture2D
	if texture == null:
		push_error("Gere e importe o PNG antes de montar a cena.")
		quit(1)
		return
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE, TILE)
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE, TILE)
	for index in range(32):
		source.create_tile(_coord(index))
	tiles.add_source(source, 0)
	ResourceSaver.save(tiles, TILESET_PATH)
	# Referência externa: o atlas e as camadas continuam editáveis no Godot.
	tiles = load(TILESET_PATH) as TileSet
	var room := Node2D.new()
	room.name = "BaseCenario"
	room.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var floor_layer := _layer(room, "Piso", tiles, 0)
	for y in range(5, 17):
		for x in range(1, 29):
			var pair := ((x * 3 + y * 5) % 4) * 2
			var seam := (x + (y % 2)) % 2
			_put(floor_layer, x, y, pair + seam)
	var back := _layer(room, "ParedeFundo", tiles, 1)
	for x in range(1, 29):
		_put(back, x, 0, 14)
		for y in range(1, 3):
			var index := 8
			if (x * 7 + y * 3) % 19 == 0:
				index = 9
			elif (x * 3 + y * 11) % 31 == 0:
				index = 10
			_put(back, x, y, index)
		_put(back, x, 3, 12)
		_put(back, x, 4, 13)
	var shadows := _layer(room, "SombrasEstruturais", tiles, 2)
	for x in range(1, 29):
		_put(shadows, x, 5, 22 + ((x + 1) % 2))
	for y in range(6, 17):
		_put(shadows, 1, y, 24)
		_put(shadows, 28, y, 25)
	_put(shadows, 1, 5, 28)
	_put(shadows, 28, 5, 29)
	for x in [5, 24]:
		_put(shadows, x, 5, 30)
	var frame := _layer(room, "VigasEParedesLaterais", tiles, 3)
	for y in range(1, 17):
		_put(frame, 0, y, 16)
		_put(frame, 29, y, 17)
	_put(frame, 0, 0, 18)
	_put(frame, 29, 0, 19)
	for x in [5, 24]:
		for y in range(1, 4):
			_put(frame, x, y, 26)
		_put(frame, x, 4, 27)
	for x in range(1, 29):
		_put(frame, x, 17, 15)
	_put(frame, 0, 17, 20)
	_put(frame, 29, 17, 21)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_PATH.get_base_dir()))
	var scene := PackedScene.new()
	scene.pack(room)
	var error := ResourceSaver.save(scene, SCENE_PATH)
	room.free()
	if error != OK:
		push_error("Não foi possível salvar a cena: %s" % error)
		quit(1)
		return
	print("Cena criada: ", SCENE_PATH)
