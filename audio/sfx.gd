class_name Sfx
extends Node
## Greybox sound effects. Each child player gets a tone built from its ToneData.

@export var pod_alarm: ToneData
@export var contract_won: ToneData
@export var contract_lost: ToneData

@onready var _pod_alarm: AudioStreamPlayer = $PodAlarm
@onready var _contract_won: AudioStreamPlayer = $ContractWon
@onready var _contract_lost: AudioStreamPlayer = $ContractLost


func _ready() -> void:
	_pod_alarm.stream = pod_alarm.build_stream()
	_contract_won.stream = contract_won.build_stream()
	_contract_lost.stream = contract_lost.build_stream()


func play_pod_alarm() -> void:
	_pod_alarm.play()


func play_contract_won() -> void:
	_contract_won.play()


func play_contract_lost() -> void:
	_contract_lost.play()
