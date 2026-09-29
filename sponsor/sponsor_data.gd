class_name SponsorData
extends Resource

enum Trigger { HEADSHOTS, MULTIKILL, UNTOUCHED_STREAK }

@export var display_name: String = "THE SPONSOR"
@export var color: Color = Color(1.0, 1.0, 1.0)
## One line shown under the meter so the player knows what this sponsor wants.
@export var wants: String = ""
@export var trigger: Trigger = Trigger.HEADSHOTS

@export_group("Drops")
## Score needed for the first drop.
@export var threshold: float = 6.0
## The threshold is multiplied by this after every drop.
@export var threshold_growth: float = 1.25
## Dropped in order, looping.
@export var pods: Array[PodData] = []

@export_group("Scoring")
## HEADSHOTS: per headshot. MULTIKILL: per chained kill, times its place in the chain.
## UNTOUCHED_STREAK: per second without taking damage.
@export var score_per_event: float = 1.0
## HEADSHOTS only: per body hit.
@export var minor_score: float = 0.25
## Score lost per miss (HEADSHOTS) or per hit taken (UNTOUCHED_STREAK). Zero means this sponsor never punishes.
@export var penalty: float = 0.0
## MULTIKILL only: seconds a kill chain stays alive after each kill.
@export var window: float = 3.0
