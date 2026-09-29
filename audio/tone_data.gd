class_name ToneData
extends Resource
## A greybox sound: a run of plain beeps, built in memory so no audio files are needed.

@export var frequency: float = 880.0
## Each beep slides to this pitch by its end. Match `frequency` for a flat tone.
@export var end_frequency: float = 880.0
@export var beep_length: float = 0.12
@export var gap_length: float = 0.08
@export var repeats: int = 3
@export_range(0.0, 1.0) var volume: float = 0.5

const SAMPLE_RATE: int = 22050


func build_stream() -> AudioStreamWAV:
	var beep_samples: int = int(beep_length * SAMPLE_RATE)
	var gap_samples: int = int(gap_length * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize((beep_samples + gap_samples) * repeats * 2)
	var cursor: int = 0
	for repeat: int in repeats:
		var phase: float = 0.0
		for index: int in beep_samples:
			var progress: float = float(index) / float(beep_samples)
			phase += TAU * lerpf(frequency, end_frequency, progress) / SAMPLE_RATE
			# Short fades at both ends stop the beep clicking.
			var envelope: float = minf(minf(progress, 1.0 - progress) * 20.0, 1.0)
			data.encode_s16(cursor, int(sin(phase) * envelope * volume * 32767.0))
			cursor += 2
		cursor += gap_samples * 2

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
