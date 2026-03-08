extends SceneTree

const SHEET_PATH := "res://assets/sprites/source/tamagotchi_sheet.png"
const OUT_DIR := "res://assets/sprites/pets"
const CANVAS_SIZE := Vector2i(128, 128)
const PADDING := 6

const PET_DEFS := [
	{"name": "pet_fiu_1", "x": 44, "y": 353, "w": 75, "h": 68},
	{"name": "pet_fiu_2", "x": 162, "y": 353, "w": 78, "h": 69},
	{"name": "pet_loica_1", "x": 156, "y": 495, "w": 86, "h": 61},
	{"name": "pet_condor_1", "x": 31, "y": 504, "w": 91, "h": 51},
	{"name": "pet_salchicha_1", "x": 729, "y": 361, "w": 106, "h": 71},
	{"name": "pet_salchicha_2", "x": 854, "y": 362, "w": 105, "h": 69},
	{"name": "pet_salchicha_3", "x": 978, "y": 361, "w": 106, "h": 70},
	{"name": "pet_salchicha_4", "x": 1103, "y": 362, "w": 105, "h": 71},
]

func _initialize() -> void:
	var img := Image.new()
	var err: int = img.load(SHEET_PATH)
	if err != OK:
		push_error("No se pudo cargar la sheet: %s" % SHEET_PATH)
		quit(1)
		return

	var out_abs := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(out_abs)

	for pet_def in PET_DEFS:
		_extract_one(img, pet_def)

	print("RESULT=OK extracted=%d out=%s" % [PET_DEFS.size(), OUT_DIR])
	quit(0)

func _extract_one(sheet: Image, pet_def: Dictionary) -> void:
	var r := Rect2i(
		int(pet_def["x"]) - PADDING,
		int(pet_def["y"]) - PADDING,
		int(pet_def["w"]) + (PADDING * 2),
		int(pet_def["h"]) + (PADDING * 2)
	)
	r = r.intersection(Rect2i(0, 0, sheet.get_width(), sheet.get_height()))
	var cut: Image = sheet.get_region(r)
	cut.convert(Image.FORMAT_RGBA8)
	_apply_gray_checker_key(cut)

	var out := Image.create(CANVAS_SIZE.x, CANVAS_SIZE.y, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))

	var trim := _alpha_bounds(cut)
	if trim.size.x <= 0 or trim.size.y <= 0:
		return
	var trimmed := cut.get_region(trim)

	var dx := int((CANVAS_SIZE.x - trimmed.get_width()) / 2)
	var dy := int((CANVAS_SIZE.y - trimmed.get_height()) / 2)
	out.blit_rect(trimmed, Rect2i(0, 0, trimmed.get_width(), trimmed.get_height()), Vector2i(dx, dy))

	var filename := "%s/%s.png" % [OUT_DIR, String(pet_def["name"])]
	out.save_png(filename)

func _apply_gray_checker_key(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var c: Color = image.get_pixel(x, y)
			var maxc: float = max(c.r, max(c.g, c.b))
			var minc: float = min(c.r, min(c.g, c.b))
			var sat: float = 0.0
			if maxc > 0.0001:
				sat = (maxc - minc) / maxc

			var is_mid_gray: bool = abs(c.r - c.g) < 0.055 and abs(c.g - c.b) < 0.055 and c.r > 0.05 and c.r < 0.95
			var is_bg: bool = sat < 0.08 and is_mid_gray

			if is_bg:
				image.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
			else:
				image.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))

func _alpha_bounds(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1

	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a <= 0.01:
				continue
			if x < min_x:
				min_x = x
			if y < min_y:
				min_y = y
			if x > max_x:
				max_x = x
			if y > max_y:
				max_y = y

	if max_x < min_x or max_y < min_y:
		return Rect2i(0, 0, 0, 0)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
