class_name GeneCatalog
extends RefCounted

enum Tags { NONE=0, FUEGO=1<<0, VIENTO=1<<1, AGUA=1<<2, TIERRA=1<<3, OXIDO=1<<4, SAGRADO=1<<5 }

const GENES: Dictionary = {
	100: { "slot": "head", "mask": Tags.NONE },
	101: { "slot": "head", "mask": Tags.FUEGO },
	102: { "slot": "head", "mask": Tags.OXIDO },
	200: { "slot": "body", "mask": Tags.NONE },
	201: { "slot": "body", "mask": Tags.AGUA },
	300: { "slot": "aura", "mask": Tags.NONE },
	301: { "slot": "aura", "mask": Tags.VIENTO }
}

static func get_mask(gene_id: int) -> int:
	if GENES.has(gene_id): return GENES[gene_id].mask
	return Tags.NONE