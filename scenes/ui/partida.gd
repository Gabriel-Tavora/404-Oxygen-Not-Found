extends CanvasLayer

const ARQUIVO_RANKING := "user://ranking.cfg"
const LABORATORIO_FISICA := "res://scenes/lab-fisica/lab-fisica.tscn"

@onready var _visor: Panel = $Visor
@onready var _tempo: Label = $Visor/Tempo

var nome_jogador := ""
var erro_ao_salvar := OK
var _inicio_ms := -1
var _tempo_final_ms := -1
var _em_missao := false
var _melhores_tempos: Dictionary[String, Dictionary] = {}


func _ready() -> void:
	_carregar_ranking()
	get_tree().scene_changed.connect(_ao_trocar_cena)
	_ao_trocar_cena.call_deferred()


func iniciar(nome: String) -> void:
	if foi_iniciada():
		return
	nome_jogador = nome.strip_edges()
	_inicio_ms = Time.get_ticks_msec()


func foi_iniciada() -> bool:
	return _inicio_ms >= 0


func tempo_decorrido_ms() -> int:
	if _tempo_final_ms >= 0:
		return _tempo_final_ms
	return Time.get_ticks_msec() - _inicio_ms if foi_iniciada() else 0


func concluir() -> void:
	if not foi_iniciada() or _tempo_final_ms >= 0:
		return
	_tempo_final_ms = tempo_decorrido_ms()
	_atualizar_visor()
	if nome_jogador.is_empty():
		return
	var chave := nome_jogador.to_lower()
	var anterior: Dictionary = _melhores_tempos.get(chave, {})
	if not anterior.is_empty() and int(anterior["tempo_ms"]) <= _tempo_final_ms:
		return
	var atualizados := _melhores_tempos.duplicate()
	atualizados[chave] = {"nome": nome_jogador, "tempo_ms": _tempo_final_ms}
	erro_ao_salvar = _salvar_ranking(atualizados)
	if erro_ao_salvar == OK:
		_melhores_tempos = atualizados
	else:
		push_warning("Falha ao salvar o ranking: %s" % error_string(erro_ao_salvar))


func reiniciar() -> void:
	nome_jogador = ""
	_inicio_ms = -1
	_tempo_final_ms = -1
	erro_ao_salvar = OK
	_atualizar_visor()


func ranking_ordenado() -> Array[Dictionary]:
	var entradas := _melhores_tempos.values()
	entradas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["tempo_ms"] == b["tempo_ms"]:
			return String(a["nome"]).nocasecmp_to(String(b["nome"])) < 0
		return a["tempo_ms"] < b["tempo_ms"]
	)
	return entradas


@warning_ignore("integer_division")
func formatar_tempo(tempo_ms: int) -> String:
	return "%02d:%02d.%03d" % [tempo_ms / 60000, (tempo_ms / 1000) % 60, tempo_ms % 1000]


func definir_missao(ativa: bool) -> void:
	_em_missao = ativa
	_atualizar_visor()


func _ao_trocar_cena() -> void:
	definir_missao(false)


func _atualizar_visor() -> void:
	var cena := get_tree().current_scene
	var caminho := cena.scene_file_path if cena else ""
	var exibir := foi_iniciada() and _tempo_final_ms < 0 and caminho in MenuPausa.CENAS_DE_JOGO
	_visor.visible = exibir
	set_process(exibir)
	if not exibir:
		return
	var margem_topo := 22.0
	if caminho == OverworldState.MAPA:
		margem_topo = 6.0
	elif _em_missao:
		margem_topo = 52.0 if caminho == LABORATORIO_FISICA else 2.0
	_visor.offset_top = margem_topo
	_visor.offset_bottom = margem_topo + 14.0
	_tempo.text = formatar_tempo(tempo_decorrido_ms())


func _process(_delta: float) -> void:
	_tempo.text = formatar_tempo(tempo_decorrido_ms())


func _carregar_ranking() -> void:
	if not FileAccess.file_exists(ARQUIVO_RANKING):
		return
	var arquivo := ConfigFile.new()
	var erro := arquivo.load(ARQUIVO_RANKING)
	if erro != OK:
		push_warning("Falha ao carregar o ranking: %s" % error_string(erro))
		return
	var registros: Variant = arquivo.get_value("ranking", "jogadores", {})
	if not registros is Dictionary:
		return
	for registro: Variant in registros.values():
		if not registro is Dictionary:
			continue
		var nome: Variant = registro.get("nome")
		var tempo_ms: Variant = registro.get("tempo_ms")
		if nome is String and not nome.strip_edges().is_empty() and tempo_ms is int and tempo_ms >= 0:
			_melhores_tempos[nome.to_lower()] = {"nome": nome, "tempo_ms": tempo_ms}


func _salvar_ranking(entradas: Dictionary[String, Dictionary]) -> Error:
	var arquivo := ConfigFile.new()
	arquivo.set_value("ranking", "jogadores", entradas)
	var temporario := ARQUIVO_RANKING + ".tmp"
	var erro := arquivo.save(temporario)
	if erro != OK:
		return erro
	return DirAccess.rename_absolute(temporario, ARQUIVO_RANKING)
