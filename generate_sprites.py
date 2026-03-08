from PIL import Image, ImageDraw

def create_sprite(path, body_rect, head_pos, tail_points, leaf_pos, color=(160, 160, 160)):
    # Canvas 128x128 transparent
    img = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Body (Grey stone)
    draw.ellipse(body_rect, fill=color, outline=(80, 80, 80), width=2)
    
    # Head
    head_rect = (head_pos[0]-15, head_pos[1]-15, head_pos[0]+15, head_pos[1]+15)
    draw.ellipse(head_rect, fill=color, outline=(80, 80, 80), width=2)
    
    # Tail
    draw.polygon(tail_points, fill=color, outline=(80, 80, 80))
    
    # Eyes (Small black dots)
    draw.ellipse((head_pos[0]-8, head_pos[1]-5, head_pos[0]-4, head_pos[1]-1), fill=(0, 0, 0))
    draw.ellipse((head_pos[0]+4, head_pos[1]-5, head_pos[0]+8, head_pos[1]-1), fill=(0, 0, 0))
    
    # Leaf (Green)
    leaf_rect = (leaf_pos[0]-8, leaf_pos[1]-12, leaf_pos[0]+8, leaf_pos[1]+2)
    draw.ellipse(leaf_rect, fill=(34, 139, 34), outline=(10, 80, 10), width=1)
    
    img.save(path)

# 1. SCOUT (Erguido)
create_sprite(
    'genagotchi/godot_project/assets/sprites/species/sprout_rex_scout/base/base_idle_00.png',
    body_rect=(44, 60, 84, 108),
    head_pos=(64, 45),
    tail_points=[(84, 85), (105, 95), (84, 95)],
    leaf_pos=(64, 30)
)

# 2. CHONK (Redondeado)
create_sprite(
    'genagotchi/godot_project/assets/sprites/species/sprout_rex_chonk/base/base_idle_00.png',
    body_rect=(35, 65, 93, 108),
    head_pos=(64, 60),
    tail_points=[(93, 85), (105, 95), (93, 95)],
    leaf_pos=(64, 45)
)

# 3. MINI-TANK (Robusto)
create_sprite(
    'genagotchi/godot_project/assets/sprites/species/sprout_rex_minitank/base/base_idle_00.png',
    body_rect=(35, 75, 93, 108),
    head_pos=(50, 65),
    tail_points=[(93, 85), (110, 95), (93, 95)],
    leaf_pos=(50, 50)
)
