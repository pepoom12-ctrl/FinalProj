extends Node
## Synthesises every sound effect and music loop of the game as .wav files
## (res://audio/sfx/*.wav, res://audio/music/*.wav). Run this scene once to
## (re)generate them. The game itself only plays the .wav files, so you can
## replace any of them with your own sound (same file name).

var _rate := 22050
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 20261015
	DirAccess.make_dir_recursive_absolute("res://audio/sfx")
	DirAccess.make_dir_recursive_absolute("res://audio/music")
	_rate = 22050
	_make_sfx()
	print("SFX_DONE")
	_rate = 16000
	_make_music()
	print("AUDIO_DONE")
	get_tree().quit()


# ------------------------------------------------------------------ helpers

func _n() -> float:
	return rng.randf_range(-1.0, 1.0)


func _ph(st: Array, i: int, f: float) -> float:
	st[i] += TAU * f / _rate
	return st[i]


func _lp(st: Array, i: int, x: float, a: float) -> float:
	st[i] += (x - st[i]) * a
	return st[i]


func _saw_t(f: float, t: float) -> float:
	return fposmod(f * t, 1.0) * 2.0 - 1.0


func _tri_t(f: float, t: float) -> float:
	return absf(fposmod(f * t, 1.0) * 4.0 - 2.0) - 1.0


func _sq_t(f: float, t: float) -> float:
	return 1.0 if fposmod(f * t, 1.0) < 0.5 else -1.0


func _hz(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)


func _notes(t: float, freqs: Array, gap: float, decay: float) -> float:
	var s := 0.0
	for k in freqs.size():
		var tt: float = t - k * gap
		if tt >= 0.0:
			var f: float = freqs[k]
			s += (sin(TAU * f * tt) + 0.35 * sin(TAU * f * 2.0 * tt)) * exp(-tt * decay)
	return s * 0.35


func _gen(dur: float, f: Callable) -> PackedFloat32Array:
	var n := int(dur * _rate)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		buf[i] = f.call(float(i) / _rate, float(i) / float(n))
	return buf


func _save(buf: PackedFloat32Array, path: String, peak: float, fade: float) -> void:
	var n := buf.size()
	var m := 0.0001
	for v in buf:
		m = maxf(m, absf(v))
	var g := peak / m
	var data := PackedByteArray()
	data.resize(n * 2)
	var fade_n := maxi(int(_rate * fade), 1)
	for i in n:
		var v: float = buf[i] * g
		if i < fade_n:
			v *= float(i) / fade_n
		elif i > n - fade_n:
			v *= float(n - i) / fade_n
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = _rate
	w.stereo = false
	w.data = data
	w.save_to_wav(path)


func _sfx(sfx_name: String, dur: float, f: Callable, peak: float = 0.85) -> void:
	_save(_gen(dur, f), "res://audio/sfx/%s.wav" % sfx_name, peak, 0.004)


# ----------------------------------------------------------------- effects

func _make_sfx() -> void:
	var st: Array = [0.0, 0.0, 0.0, 0.0]

	# --- UI
	_sfx("ui_hover", 0.06, func(_t, p): return sin(_ph(st, 0, 1400.0)) * exp(-p * 6.0) * 0.5, 0.5)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("ui_click", 0.14, func(_t, p): return sin(_ph(st, 0, lerpf(500.0, 900.0, p))) * exp(-p * 5.0) + _n() * exp(-p * 30.0) * 0.4, 0.7)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("ui_back", 0.14, func(_t, p): return sin(_ph(st, 0, lerpf(700.0, 380.0, p))) * exp(-p * 5.0) + _n() * exp(-p * 30.0) * 0.3, 0.7)
	_sfx("select_weapon", 1.0, func(t, _p): return _notes(t, [523.25, 659.25, 783.99, 1046.5], 0.09, 4.5), 0.85)
	_sfx("type_tick", 0.03, func(_t, p): return _n() * exp(-p * 40.0) * 0.4 + sin(TAU * 900.0 * p * 0.03) * exp(-p * 30.0) * 0.3, 0.4)

	# --- weapons
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("fire_cast", 0.38, func(_t, p): return _lp(st, 1, _n(), lerpf(0.5, 0.07, p)) * pow(1.0 - p, 1.2) * 2.0 + sin(_ph(st, 0, lerpf(170.0, 70.0, p))) * 0.5 * exp(-p * 4.0) + (_n() * 0.5 if rng.randf() < 0.03 else 0.0), 0.8)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("ice_cast", 0.3, func(_t, p): return sin(_ph(st, 0, 1900.0 + sin(_ph(st, 1, 45.0)) * 320.0)) * exp(-p * 6.0) + sin(_ph(st, 2, 3300.0)) * exp(-p * 9.0) * 0.4, 0.7)
	_sfx("lightning_cast", 0.16, func(t, p): return _saw_t(190.0, t) * (0.6 + 0.4 * _n()) * exp(-p * 4.0) + _n() * exp(-p * 9.0) * 0.8, 0.7)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("arrow_shoot", 0.26, func(_t, p): return _n() * exp(-p * 18.0) * 0.5 + sin(_ph(st, 0, lerpf(420.0, 300.0, p))) * exp(-p * 14.0) * 0.6, 0.65)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("fireball", 0.45, func(_t, p): return _lp(st, 1, _n(), lerpf(0.4, 0.1, p)) * (1.0 - p) * 1.5 + sin(_ph(st, 0, lerpf(300.0, 120.0, p))) * 0.4 * (1.0 - p), 0.8)

	# --- combat
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("hit_enemy", 0.12, func(_t, p): return _n() * exp(-p * 25.0) * 0.6 + sin(_ph(st, 0, lerpf(220.0, 90.0, p))) * exp(-p * 14.0), 0.75)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("enemy_die", 0.3, func(_t, p): return sin(_ph(st, 0, lerpf(500.0, 70.0, p))) * exp(-p * 5.0) * 0.8 + _n() * exp(-p * 18.0) * 0.4, 0.8)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("player_hurt", 0.3, func(_t, p): return (fposmod(_ph(st, 0, lerpf(260.0, 110.0, p)) / TAU, 1.0) * 2.0 - 1.0) * exp(-p * 6.0) * 0.6 + _n() * exp(-p * 20.0) * 0.3, 0.8)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("player_die", 1.3, func(_t, p): return sin(_ph(st, 0, lerpf(330.0, 55.0, p * p))) * exp(-p * 2.2) + (fposmod(_ph(st, 1, lerpf(165.0, 40.0, p)) / TAU, 1.0) * 2.0 - 1.0) * 0.3 * exp(-p * 3.0) + _lp(st, 2, _n(), 0.05) * 0.8 * exp(-p * 2.0), 0.85)

	# --- skills (rune codes)
	_sfx("strat_input", 0.05, func(t, p): return _sq_t(1000.0, t) * exp(-p * 5.0) * 0.4, 0.5)
	_sfx("strat_ready", 0.24, func(t, _p): return sin(TAU * (660.0 if t < 0.1 else 990.0) * t) * exp(-fposmod(t, 0.1) * 12.0) * 0.6, 0.7)
	_sfx("strat_deny", 0.28, func(t, p): return _sq_t(150.0 + sin(t * 60.0) * 8.0, t) * 0.4 * exp(-p * 3.0), 0.6)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("strat_confirm", 0.4, func(_t, p): return sin(_ph(st, 0, lerpf(400.0, 1600.0, p))) * (1.0 - p) * 0.5 + _notes(_t, [880.0, 1320.0], 0.08, 7.0), 0.75)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("meteor_incoming", 0.85, func(_t, p): return sin(_ph(st, 0, lerpf(2400.0, 260.0, p))) * (0.25 + p * 0.5) * 0.8 + _lp(st, 1, _n(), 0.15) * p * 0.6, 0.75)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("explosion_big", 1.4, func(_t, p): return _lp(st, 1, _n(), lerpf(0.35, 0.02, p)) * exp(-p * 3.2) * 2.4 + sin(_ph(st, 0, lerpf(75.0, 28.0, p))) * exp(-p * 3.0), 0.95)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("explosion_small", 0.55, func(_t, p): return _lp(st, 1, _n(), lerpf(0.3, 0.04, p)) * exp(-p * 5.0) * 2.2 + sin(_ph(st, 0, lerpf(110.0, 45.0, p))) * exp(-p * 6.0), 0.8)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("golem_summon", 1.1, func(_t, p): return (fposmod(_ph(st, 0, lerpf(60.0, 95.0, p)) / TAU, 1.0) * 2.0 - 1.0) * 0.5 * sin(PI * p) + _lp(st, 1, _n(), 0.08) * 0.8 * sin(PI * p) + sin(_ph(st, 2, lerpf(400.0, 1400.0, p))) * 0.25 * p * (1.0 - p) * 4.0, 0.85)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("stone_hit", 0.15, func(_t, p): return _lp(st, 1, _n(), 0.12) * exp(-p * 18.0) * 2.0 + sin(TAU * 110.0 * p * 0.15) * exp(-p * 20.0), 0.8)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("stone_break", 0.6, func(_t, p): return _lp(st, 1, _n(), 0.2) * exp(-p * 5.0) * (0.6 + 0.4 * sin(p * 60.0)) * 2.0, 0.85)

	# --- objectives & pickups
	_sfx("objective_tick", 0.3, func(t, _p): return (sin(TAU * 880.0 * t) + 0.5 * sin(TAU * 1320.0 * t)) * exp(-t * 9.0) * 0.5, 0.6)
	_sfx("objective_done", 0.9, func(t, _p): return _notes(t, [523.25, 659.25, 783.99, 1046.5, 1318.5], 0.09, 5.0), 0.8)
	_sfx("main_complete", 1.8, func(t, _p): return (_saw_t(261.6, t) + _saw_t(329.6, t) + _saw_t(392.0, t) + _saw_t(523.3, t)) * exp(-t * 2.5) * 0.18 * minf(t / 0.02, 1.0) + (_saw_t(196.0, t - 0.45) + _saw_t(246.9, t - 0.45) + _saw_t(392.0, t - 0.45) + _saw_t(587.3, t - 0.45)) * exp(-maxf(t - 0.45, 0.0) * 2.5) * 0.18 * (1.0 if t >= 0.45 else 0.0) + (_saw_t(261.6, t - 0.9) + _saw_t(329.6, t - 0.9) + _saw_t(392.0, t - 0.9) + _saw_t(523.3, t - 0.9) + _saw_t(1046.5, t - 0.9)) * exp(-maxf(t - 0.9, 0.0) * 1.6) * 0.2 * (1.0 if t >= 0.9 else 0.0), 0.85)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("pickup", 0.35, func(_t, p): var ph := _ph(st, 0, lerpf(700.0, 1800.0, p)); return (sin(ph) + 0.4 * sin(ph * 2.0)) * exp(-p * 4.0) * 0.6, 0.7)
	_sfx("heal", 0.8, func(t, p): return (sin(TAU * lerpf(520.0, 1040.0, p) * t) + 0.5 * sin(TAU * 1560.0 * t)) * sin(PI * p) * (0.7 + 0.3 * sin(t * 40.0)) * 0.5, 0.7)
	_sfx("sabotage", 0.6, func(t, p): return _n() * (1.0 if sin(t * 180.0) > 0.0 else 0.0) * exp(-p * 5.0) * 0.5 + sin(TAU * lerpf(1200.0, 200.0, p) * t) * 0.4 * exp(-p * 5.0), 0.75)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("valve", 0.7, func(t, p): return (sin(TAU * 420.0 * t) + 0.7 * sin(TAU * 630.0 * t) + 0.4 * sin(TAU * 1100.0 * t)) * exp(-t * 10.0) * 0.5 + _lp(st, 1, _n(), 0.4) * exp(-p * 3.0) * 0.35, 0.8)
	_sfx("lantern", 0.9, func(t, _p): return (sin(TAU * 392.0 * t) + 0.8 * sin(TAU * 587.3 * t) + 0.6 * sin(TAU * 784.0 * t)) * exp(-t * 3.5) * 0.35 * minf(t / 0.03, 1.0), 0.75)
	_sfx("core_pickup", 0.7, func(t, p): return (sin(TAU * lerpf(300.0, 900.0, p) * t) + 0.6 * sin(TAU * 1200.0 * t)) * exp(-p * 3.0) * 0.5, 0.75)

	# --- portal / extraction
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("portal_open", 2.0, func(t, p): return sin(_ph(st, 0, lerpf(100.0, 400.0, p))) * p * (1.0 - p * 0.4) + (sin(TAU * 1200.0 * t + sin(t * 9.0) * 3.0) + sin(TAU * 1800.0 * t + sin(t * 7.0) * 3.0)) * 0.12 * sin(PI * p) + _lp(st, 1, _n(), 0.1) * sin(PI * p) * 0.6, 0.85)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("portal_activate", 1.2, func(_t, p): return ((fposmod(_ph(st, 0, lerpf(120.0, 900.0, p * p)) / TAU, 1.0) * 2.0 - 1.0) * 0.4 + sin(_ph(st, 1, lerpf(300.0, 2400.0, p))) * 0.4) * (1.0 if p < 0.8 else (1.0 - p) / 0.2), 0.85)
	_sfx("portal_hum", 4.0, func(t, _p): return sin(TAU * 110.0 * t) * 0.5 * (0.7 + 0.3 * sin(TAU * 2.0 * t)) + sin(TAU * 220.0 * t) * 0.3 + sin(TAU * 330.25 * t) * 0.12 * (0.5 + 0.5 * sin(TAU * 0.5 * t)) + sin(TAU * 880.0 * t + sin(TAU * 1.0 * t) * 2.0) * 0.06, 0.6)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("portal_warp", 1.8, func(_t, p): return _lp(st, 1, _n(), lerpf(0.02, 0.6, p)) * sin(PI * p) * 1.6 + sin(_ph(st, 0, lerpf(200.0, 3000.0, p * p))) * sin(PI * p) * 0.4, 0.9)
	_sfx("level_clear", 2.6, func(t, _p): return _notes(t, [523.25, 659.25, 783.99, 1046.5], 0.18, 3.0) + (sin(TAU * 523.25 * t) + sin(TAU * 659.25 * t) + sin(TAU * 783.99 * t) + sin(TAU * 1046.5 * t)) * 0.12 * (1.0 if t > 0.8 else 0.0) * exp(-maxf(t - 0.8, 0.0) * 1.6), 0.85)

	# --- boss
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("boss_slam", 1.1, func(_t, p): return _lp(st, 1, _n(), lerpf(0.12, 0.01, p)) * exp(-p * 4.0) * 3.5 + sin(_ph(st, 0, lerpf(55.0, 25.0, p))) * exp(-p * 3.0) * 1.2 + _n() * exp(-p * 60.0), 0.95)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("boss_charge", 0.7, func(_t, p): return (fposmod(_ph(st, 0, lerpf(70.0, 180.0, p)) / TAU, 1.0) * 2.0 - 1.0) * 0.6 * minf(p * 6.0, 1.0) + _lp(st, 1, _n(), 0.1) * p * 0.8, 0.85)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("boss_roar", 1.6, func(t, p): return ((fposmod(_ph(st, 0, 95.0 + sin(TAU * 6.0 * t) * 6.0) / TAU, 1.0) * 2.0 - 1.0) * 0.55 + _lp(st, 1, _n(), 0.25) * 0.5) * pow(sin(PI * p), 0.5), 0.9)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("boss_die", 2.4, func(t, p): return _lp(st, 1, _n(), lerpf(0.2, 0.02, p)) * (exp(-t * 3.0) + exp(-maxf(t - 0.35, 0.0) * 3.0) * (1.0 if t >= 0.35 else 0.0) + exp(-maxf(t - 0.8, 0.0) * 2.5) * (1.0 if t >= 0.8 else 0.0)) * 1.8 + sin(_ph(st, 0, lerpf(90.0, 24.0, p))) * exp(-p * 1.6), 0.95)
	st = [0.0, 0.0, 0.0, 0.0]
	_sfx("spin_whoosh", 0.55, func(_t, p): return _lp(st, 1, _n(), lerpf(0.05, 0.5, p)) * sin(PI * p) * 1.8, 0.75)


# ------------------------------------------------------------------- music

func _new_buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * _rate))
	return b


## Pad: soft sustained chord. Release tail wraps around (seamless loop).
func _pad(buf: PackedFloat32Array, t0: float, dur: float, freqs: Array, amp: float, att: float, rel: float) -> void:
	var n := buf.size()
	var s0 := int(t0 * _rate)
	var count := int((dur + rel) * _rate)
	var k := float(freqs.size())
	for i in count:
		var t := float(i) / _rate
		var env := minf(t / att, 1.0)
		if t > dur:
			env *= maxf(0.0, 1.0 - (t - dur) / rel)
		var v := 0.0
		for f in freqs:
			v += sin(TAU * f * t) * 0.6 + _saw_t(f * 1.004, t) * 0.1 + _saw_t(f * 0.996, t) * 0.1
		buf[(s0 + i) % n] += v * env * amp / k


func _pluck(buf: PackedFloat32Array, t0: float, freq: float, amp: float, decay: float) -> void:
	var n := buf.size()
	var s0 := int(t0 * _rate)
	var count := int(0.9 * _rate)
	for i in count:
		var t := float(i) / _rate
		var v := (_tri_t(freq, t) * 0.7 + sin(TAU * freq * 2.0 * t) * 0.2) * exp(-t * decay)
		buf[(s0 + i) % n] += v * amp


func _bass(buf: PackedFloat32Array, t0: float, dur: float, freq: float, amp: float, saw: bool) -> void:
	var n := buf.size()
	var s0 := int(t0 * _rate)
	var count := int((dur + 0.08) * _rate)
	for i in count:
		var t := float(i) / _rate
		var env := minf(t / 0.01, 1.0)
		if t > dur:
			env *= maxf(0.0, 1.0 - (t - dur) / 0.08)
		var v := sin(TAU * freq * t) * 0.8 + _tri_t(freq, t) * 0.3
		if saw:
			v = sin(TAU * freq * t) * 0.6 + _saw_t(freq, t) * 0.35
		buf[(s0 + i) % n] += v * env * amp


func _kick(buf: PackedFloat32Array, t0: float, amp: float) -> void:
	var n := buf.size()
	var s0 := int(t0 * _rate)
	var count := int(0.22 * _rate)
	var phase := 0.0
	for i in count:
		var t := float(i) / _rate
		phase += TAU * (45.0 + 90.0 * exp(-t * 28.0)) / _rate
		buf[(s0 + i) % n] += sin(phase) * exp(-t * 14.0) * amp


func _tom(buf: PackedFloat32Array, t0: float, amp: float, base: float) -> void:
	var n := buf.size()
	var s0 := int(t0 * _rate)
	var count := int(0.4 * _rate)
	var phase := 0.0
	for i in count:
		var t := float(i) / _rate
		phase += TAU * (base + base * exp(-t * 8.0)) / _rate
		buf[(s0 + i) % n] += sin(phase) * exp(-t * 8.0) * amp


func _noise_hit(buf: PackedFloat32Array, t0: float, amp: float, decay: float, dur: float) -> void:
	var n := buf.size()
	var s0 := int(t0 * _rate)
	var count := int(dur * _rate)
	for i in count:
		var t := float(i) / _rate
		buf[(s0 + i) % n] += _n() * exp(-t * decay) * amp


func _snare(buf: PackedFloat32Array, t0: float, amp: float) -> void:
	_noise_hit(buf, t0, amp, 18.0, 0.22)
	var n := buf.size()
	var s0 := int(t0 * _rate)
	for i in int(0.12 * _rate):
		var t := float(i) / _rate
		buf[(s0 + i) % n] += sin(TAU * 190.0 * t) * exp(-t * 25.0) * amp * 0.5


func _bell(buf: PackedFloat32Array, t0: float, freq: float, amp: float) -> void:
	var n := buf.size()
	var s0 := int(t0 * _rate)
	var count := int(2.2 * _rate)
	for i in count:
		var t := float(i) / _rate
		var v := sin(TAU * freq * t + 2.0 * sin(TAU * freq * 3.5 * t) * exp(-t * 3.0)) * exp(-t * 1.6)
		buf[(s0 + i) % n] += v * amp


func _stab(buf: PackedFloat32Array, t0: float, freqs: Array, amp: float) -> void:
	var n := buf.size()
	var s0 := int(t0 * _rate)
	var count := int(0.7 * _rate)
	for i in count:
		var t := float(i) / _rate
		var v := 0.0
		for f in freqs:
			v += _saw_t(f, t) + _saw_t(f * 1.01, t)
		buf[(s0 + i) % n] += v * 0.5 * exp(-t * 3.5) * minf(t / 0.02, 1.0) * amp / float(freqs.size())


func _wind(buf: PackedFloat32Array, amp: float) -> void:
	var n := buf.size()
	var a := 0.0
	var b := 0.0
	for i in n:
		var t := float(i) / _rate
		a += (_n() - a) * 0.04
		b += (a - b) * 0.2
		buf[i] += b * (0.5 + 0.5 * sin(TAU * t / (n / _rate / 3.0))) * amp


func _music(track_name: String, buf: PackedFloat32Array) -> void:
	_save(buf, "res://audio/music/%s.wav" % track_name, 0.7, 0.01)


func _freqs(midis: Array) -> Array:
	var out: Array = []
	for m in midis:
		out.append(_hz(m))
	return out


func _make_music() -> void:
	_track_menu()
	print("menu ok")
	_track_graveyard()
	print("graveyard ok")
	_track_forest()
	print("forest ok")
	_track_volcano()


## Menu: epic A-minor, pad + arpeggio + soft pulse.
func _track_menu() -> void:
	var beat := 60.0 / 84.0
	var buf := _new_buf(beat * 4.0 * 8.0)
	var roots := [45, 41, 48, 43]
	var chords := [[57, 60, 64], [53, 57, 60], [60, 64, 67], [55, 59, 62]]
	var pattern := [0, 1, 2, 1, 2, 1, 0, 1]
	for b in 8:
		var t0 := b * 4.0 * beat
		var ch: Array = chords[b % 4]
		_pad(buf, t0, 4.0 * beat, _freqs(ch), 0.55, 0.7, 0.9)
		_bass(buf, t0, beat * 1.9, _hz(roots[b % 4]), 0.5, false)
		_bass(buf, t0 + beat * 2.0, beat * 1.9, _hz(roots[b % 4]), 0.45, false)
		for k in 8:
			var m: int = ch[pattern[k]] + 12
			_pluck(buf, t0 + k * beat * 0.5, _hz(m), 0.3, 4.5)
		_kick(buf, t0, 0.4)
		_kick(buf, t0 + beat * 2.0, 0.3)
		if b % 4 == 0:
			_bell(buf, t0, _hz(81), 0.18)
	_music("menu", buf)


## Graveyard: eerie D-minor drone, sparse bells, heartbeat, wind.
func _track_graveyard() -> void:
	var beat := 1.0
	var total := 24.0
	var buf := _new_buf(total)
	_pad(buf, 0.0, total, _freqs([38, 50]) + [_hz(38) * 1.004], 0.55, 2.0, 2.0)
	var chords := [[50, 53, 57], [46, 50, 53], [55, 58, 62], [57, 61, 64], [50, 53, 57], [46, 50, 53]]
	var scale := [74, 77, 79, 81, 84, 86]
	for b in 6:
		var t0 := b * 4.0 * beat
		_pad(buf, t0, 4.0 * beat, _freqs(chords[b]), 0.35, 1.2, 1.4)
		for pos in [0.0, 1.5, 2.5, 3.0]:
			if rng.randf() < 0.55:
				_bell(buf, t0 + pos * beat, _hz(scale[rng.randi() % scale.size()]), 0.16)
		for k in 4:
			_kick(buf, t0 + k * beat, 0.22 if k % 2 == 0 else 0.12)
	_wind(buf, 0.5)
	_music("graveyard", buf)


## Forest: mystical D-major harp arpeggios, chimes, light shaker.
func _track_forest() -> void:
	var beat := 60.0 / 96.0
	var buf := _new_buf(beat * 4.0 * 8.0)
	var chords := [[50, 54, 57], [57, 61, 64], [59, 62, 66], [55, 59, 62]]
	var roots := [38, 45, 47, 43]
	var pattern := [0, 1, 2, 3, 4, 5, 4, 3]
	var pent := [86, 88, 90, 93, 95]
	for b in 8:
		var t0 := b * 4.0 * beat
		var ch: Array = chords[b % 4]
		var tones := [ch[0], ch[1], ch[2], ch[0] + 12, ch[1] + 12, ch[2] + 12]
		_pad(buf, t0, 4.0 * beat, _freqs(ch), 0.4, 0.8, 1.0)
		_bass(buf, t0, beat * 1.9, _hz(roots[b % 4]), 0.45, false)
		_bass(buf, t0 + beat * 2.0, beat * 1.9, _hz(roots[b % 4] + 7), 0.35, false)
		for k in 8:
			_pluck(buf, t0 + k * beat * 0.5, _hz(tones[pattern[k]]), 0.32, 4.0)
			_noise_hit(buf, t0 + k * beat * 0.5 + beat * 0.25, 0.07, 55.0, 0.06)
		_bell(buf, t0 + beat * (1.0 + float(rng.randi() % 3)), _hz(pent[rng.randi() % pent.size()]), 0.12)
	_music("forest", buf)


## Volcano: heavy E-minor, war drums, saw bass ostinato, brass stabs.
func _track_volcano() -> void:
	var beat := 60.0 / 120.0
	var buf := _new_buf(beat * 4.0 * 8.0)
	var roots := [40, 36, 38, 35]
	var chords := [[52, 55, 59], [48, 52, 55], [50, 54, 57], [47, 50, 54]]
	for b in 8:
		var t0 := b * 4.0 * beat
		var r: int = roots[b % 4]
		_pad(buf, t0, 4.0 * beat, _freqs(chords[b % 4]), 0.35, 0.3, 0.6)
		for k in 8:
			var m: int = r + (12 if k % 4 == 3 else 0)
			_bass(buf, t0 + k * beat * 0.5, beat * 0.45, _hz(m), 0.45, true)
			_noise_hit(buf, t0 + k * beat * 0.5, 0.1, 60.0, 0.05)
		for k in 4:
			_kick(buf, t0 + k * beat, 0.6)
		_snare(buf, t0 + beat, 0.3)
		_snare(buf, t0 + beat * 3.0, 0.3)
		_stab(buf, t0, _freqs([r + 12, r + 19, r + 24]), 0.45)
		_stab(buf, t0 + beat * 2.5, _freqs([r + 12, r + 19, r + 24]), 0.35)
		if b % 4 == 3:
			_tom(buf, t0 + beat * 3.0, 0.5, 70.0)
			_tom(buf, t0 + beat * 3.5, 0.5, 90.0)
			_tom(buf, t0 + beat * 3.75, 0.5, 110.0)
		if b == 0:
			_noise_hit(buf, t0, 0.35, 3.0, 1.5)
	_music("volcano", buf)
