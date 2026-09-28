class_name Hitbox
extends Area3D
## A hitscan-only region that forwards hits to a damageable. Used for heads.

@export var is_head: bool = false
## Node that implements take_hit(hit: HitInfo).
@export var target: Node
