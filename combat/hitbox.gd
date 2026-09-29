class_name Hitbox
extends Area3D
## A hitscan-only region that forwards hits to a damageable. Used for weak points.
## Anything drawn as a child of this node is hidden while the weak point is shut.

enum Exposure {
	ALWAYS,
	## Only open while its owner is winding up an attack or recovering from one.
	WHILE_ATTACKING,
}

## True for a weak point: hits here take the weapon's weak-point multiplier.
@export var is_head: bool = false
## Node that implements take_hit(hit: HitInfo).
@export var target: Node
@export var exposure: Exposure = Exposure.ALWAYS

var _layer: int = 0


func _ready() -> void:
	_layer = collision_layer


func set_exposed(exposed: bool) -> void:
	collision_layer = _layer if exposed else 0
	visible = exposed
