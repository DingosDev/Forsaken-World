extends Node2D

enum CELL_TYPE {
	NONE,
	WALL,
	FALL
}

@export var room_size: Rect2
@export var maps: Array[Texture]
@export var background: Texture
@export var background_size: Vector2
@export var ground_tile: TileSet

var currentWave := -1:
	set(value):
		currentWave = value
		Game.wave = value

var spawning:bool = false

@onready var wavetext := preload("res://objects/effects/obj_wavetext.tscn")
@onready var hud := $obj_hud

var player:CharacterBody2D
var level_modulate:CanvasModulate
var parallax_modulate:CanvasModulate
var tilemap:TileMapLayer

var leveledUpTimes = 0

func _ready():
	if !Engine.is_editor_hint():
		create_background()
		create_level()
	
	child_entered_tree.connect(func(node): if !node is CanvasLayer: node.show_behind_parent = true)
	Game.LeveledUp.connect(func(): leveledUpTimes += 1)

func create_background():
		var bg_frames = background.get_width()/background_size.x
		var bg_parallax = ParallaxBackground.new()
		var mod = CanvasModulate.new()
		
		bg_parallax.layer = -1
		
		for i in bg_frames:
			var parallax = ParallaxLayer.new()
			var sprite = Sprite2D.new()
			
			sprite.texture = background
			sprite.region_enabled = true
			sprite.region_rect = Rect2(Vector2(background_size.x * i, 0), background_size)
			sprite.centered = false
			
			parallax.motion_mirroring = background_size
			parallax.motion_scale.x = .05 * i
			
			parallax.add_child(sprite)
			bg_parallax.add_child(parallax)
		
		parallax_modulate = mod
		bg_parallax.add_child(mod)
		
		add_child(bg_parallax)

func create_level():
		tilemap = TileMapLayer.new()
		tilemap.set_tile_set(ground_tile)
		
		level_modulate = CanvasModulate.new()
		
		add_child(level_modulate)
		add_child(tilemap)
		
		var randomMap = randi_range(0, maps.size()-1)
		var mapData = maps[randomMap].get_image()
		var w = mapData.get_width()
		var h = mapData.get_height()
		
		var ground = []
		
		room_size = Rect2(Vector2(16, 0), Vector2(w-1, h-1) * 16)
		
		for y in h:
			for x in w:
				var color = mapData.get_pixel(x, y)
				
				match color:
					Color("ffffff"): ground.append(Vector2(x, y))
					
					Color("4d9be6"):
						var p = preload("res://objects/obj_player.tscn").instantiate()
						var weapon = preload("res://objects/obj_weapon.tscn").instantiate()
						var camera = preload("res://objects/obj_camera.tscn").instantiate()
						
						p.position = Vector2(x*16+8, y*16+24)
						
						weapon.player = p
						
						camera.target_node = p
						
						add_child(p)
						add_child(weapon)
						add_child(camera)
						
						player = p
		
		tilemap.set_cells_terrain_connect(ground, 0, 0)

func new_wave(id:int):
	var wavetextInst = wavetext.instantiate()
	wavetextInst.bbcode_text = "[center]Wave " + str(id+1)
	hud.call_deferred("add_child", wavetextInst)
	
	currentWave = id
	var waveData = Game.waveData[id]
	
	for child in hud.get_children(): if child is RichTextLabel: child.queue_free()
	
	spawning = true
	
	await get_tree().create_timer(2).timeout
	
	for content in waveData:
		for i in waveData[content][1]:
			var enemyInst = Game.enemiesID[waveData[content][0]].instantiate()
			
			enemyInst.player = player
			
			$enemies.add_child(enemyInst)
			
			await get_tree().create_timer(1.0).timeout
		
		await get_tree().create_timer(2.0).timeout
	
	spawning = false

var wave_delay = 60

func _process(delta: float) -> void:
	if currentWave+1 < Game.waveData.size():
		if $enemies.get_child_count() == 0 && !spawning:
			wave_delay -= 60*delta
			
			if wave_delay > 0: return
			
			if leveledUpTimes:
				leveledUpTimes -= 1
				
				add_child(preload("res://scenes/scn_blessingsChoice.tscn").instantiate())
				process_mode = PROCESS_MODE_DISABLED
			
			elif !get_node_or_null(^"scn_blessingsChoice"):
				new_wave(currentWave+1)
			
			wave_delay = 60

func _notification(what):
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN: get_tree().paused = 0
	elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT: get_tree().paused = 1
