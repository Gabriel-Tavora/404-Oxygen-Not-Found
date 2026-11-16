extends Control

const MEDIDOR := preload("res://scenes/ui/medidor-treinamento.tscn")
const DURACAO_APROXIMACAO := 0.32
const DURACAO_FOCO := 1.5
const DURACAO_RETORNO := 0.36

@onready var _medidores := $Faixa/Medidores.get_children()
@onready var _foco: ColorRect = $Foco
@onready var _aviso: Control = $Aviso
@onready var _mensagem: Label = $Aviso/Balao/Mensagem
@onready var _tempo_aviso: Timer = $TempoAviso
@onready var _som_aviso: AudioStreamPlayer = $SomAviso

var _laboratorio_pendente: StringName
var _premiada_pendente := false
var _zoom: Tween
var _medidor_original: Control
var _medidor_ampliado: Control


func _ready() -> void:
	var fonte_aviso := FontVariation.new()
	fonte_aviso.base_font = _mensagem.get_theme_font(&"font")
	fonte_aviso.fallbacks = [ThemeDB.fallback_font]
	_mensagem.add_theme_font_override(&"font", fonte_aviso)
	ProgressoConhecimento.missao_finalizada.connect(_registrar_resultado)
	_tempo_aviso.timeout.connect(_aviso.hide)


func ocultar_durante_missao() -> void:
	_encerrar_zoom()
	_tempo_aviso.stop()
	_som_aviso.stop()
	_aviso.hide()
	hide()


func restaurar_apos_missao() -> void:
	show()
	if not _laboratorio_pendente.is_empty():
		_mostrar_resultado(_laboratorio_pendente, _premiada_pendente)
		_laboratorio_pendente = &""


func _registrar_resultado(laboratorio: StringName, premiada: bool) -> void:
	if visible:
		_mostrar_resultado(laboratorio, premiada)
	else:
		_laboratorio_pendente = laboratorio
		_premiada_pendente = premiada


func _mostrar_resultado(laboratorio: StringName, premiada: bool) -> void:
	_encerrar_zoom()
	for medidor in _medidores:
		var corresponde: bool = laboratorio in medidor.laboratorios
		var antes: int = medidor.concluidas_exibidas
		var treino_completo: bool = medidor.atualizar()
		if not corresponde:
			continue
		if premiada:
			_ampliar_medidor(medidor, antes)
			_mensagem.text = "+1 em %s" % medidor.titulo
			if treino_completo:
				_mensagem.text += "\nTreino completo!"
		else:
			_mensagem.text = "Repetição concluída.\nVocê já ganhou o ponto de %s." % medidor.titulo
		_aviso.show()
		_som_aviso.play()
		_tempo_aviso.start(2.8 if premiada else 3.8)


func _ampliar_medidor(medidor: Control, antes: int) -> void:
	var ampliado = MEDIDOR.instantiate()
	ampliado.titulo = medidor.titulo
	ampliado.cor = medidor.cor
	ampliado.icone = medidor.icone
	ampliado.laboratorios = medidor.laboratorios
	_foco.add_child(ampliado)
	ampliado.size = medidor.size
	ampliado.exibir(antes)

	var origem := medidor.global_position - _foco.global_position
	var escala := Vector2.ONE * minf(2.2, (size.x - 24.0) / medidor.size.x)
	var destino := (Vector2(size.x * 0.5, size.y * 0.25) - medidor.size * escala * 0.5).round()
	ampliado.position = origem
	_medidor_ampliado = ampliado
	_medidor_original = medidor
	_medidor_original.modulate.a = 0.0
	_foco.color.a = 0.0
	_foco.show()

	_zoom = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_zoom.tween_property(ampliado, "position", destino, DURACAO_APROXIMACAO)
	_zoom.parallel().tween_property(ampliado, "scale", escala, DURACAO_APROXIMACAO)
	_zoom.parallel().tween_property(_foco, "color:a", 0.54, DURACAO_APROXIMACAO)
	_zoom.tween_callback(ampliado.atualizar.bind(true))
	_zoom.tween_interval(DURACAO_FOCO)
	_zoom.tween_property(ampliado, "position", origem, DURACAO_RETORNO)
	_zoom.parallel().tween_property(ampliado, "scale", Vector2.ONE, DURACAO_RETORNO)
	_zoom.parallel().tween_property(_foco, "color:a", 0.0, DURACAO_RETORNO)
	_zoom.finished.connect(_encerrar_zoom)


func _encerrar_zoom() -> void:
	if _zoom and _zoom.is_valid():
		_zoom.kill()
	_zoom = null
	if is_instance_valid(_medidor_original):
		_medidor_original.modulate.a = 1.0
	_medidor_original = null
	if is_instance_valid(_medidor_ampliado):
		_medidor_ampliado.hide()
		_medidor_ampliado.queue_free()
	_medidor_ampliado = null
	_foco.hide()
