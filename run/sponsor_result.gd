class_name SponsorResult
extends RefCounted
## How one sponsor felt about the run.

var sponsor: SponsorData
var drops: int = 0
## Progress toward the next drop when the run ended, 0.0 to 1.0.
var standing: float = 0.0
var reputation_before: int = 0
var reputation_after: int = 0
