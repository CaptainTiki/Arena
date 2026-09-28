class_name HitInfo
extends RefCounted
## Everything known about one resolved shot or blow. Passed to take_hit() and up the spine.

var damage: float = 0.0
var is_headshot: bool = false
var position: Vector3 = Vector3.ZERO
var normal: Vector3 = Vector3.UP
var direction: Vector3 = Vector3.FORWARD
## The damageable that was struck, or null when the hit landed on the world.
var target: Node = null
var source: Node = null


func landed() -> bool:
	return target != null
