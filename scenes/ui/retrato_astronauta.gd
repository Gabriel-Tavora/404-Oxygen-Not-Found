extends TextureRect

const POSE_FRONTAL := &"idle_down"
const ALTURA_RETRATO := 90.0


func _ready() -> void:
	var dados := PersonagemEscolhido.dados
	if dados == null:
		return
	var cabelo := PersonagemEscolhido.cabelo
	var indice := cabelo.indice if cabelo else PersonagemEscolhido.indice_cabelo
	var frames := dados.frames(indice)
	if frames == null or not frames.has_animation(POSE_FRONTAL):
		return
	if frames.get_frame_count(POSE_FRONTAL) == 0:
		return
	var quadro := frames.get_frame_texture(POSE_FRONTAL, 0) as AtlasTexture
	if quadro == null:
		return

	# Os quadros da seleção começam no topo do cabelo. Recorta até os ombros.
	var recorte := AtlasTexture.new()
	recorte.atlas = quadro.atlas
	recorte.region = Rect2(quadro.region.position, Vector2(
		quadro.region.size.x, minf(ALTURA_RETRATO, quadro.region.size.y)
	))
	recorte.filter_clip = true
	texture = recorte
	material = dados.material_corpo
