class_name SponsorResult
extends RefCounted
## How one sponsor felt about the fight, and what it paid.

var sponsor: SponsorData
## Everything the sponsor liked, less everything it didn't, over the whole fight.
var score: float = 0.0
var drops: int = 0
## True when this sponsor had asked for the contract, and so paid double.
var requested: bool = false
var favour_before: int = 0
var favour_after: int = 0
