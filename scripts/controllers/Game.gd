extends Node

signal SceneChangeCompleted
signal HPChanged
signal ManaChanged
signal XPChanged
signal LeveledUp
signal WeaponChanged
signal WeaponUpgraded

var trans = preload("res://scripts/controllers/Transition.tscn").instantiate()

const GRAVITY = 432.0

var wave = 0

var blessings = []

var level = 1
var xp = 0:
	set(value):
		var nextLevelXP = 1*pow(level, 2.0)
		xp = value
		
		XPChanged.emit()
		
		if value >= nextLevelXP:
			xp -= nextLevelXP
			level += 1
			
			LeveledUp.emit()
			
			var currentHPPercentage = hp/mhp
			var currentManaPercentage = mana/mhp
			
			mhp += (level - 1) * .8
			atk += (level - 1) * .5
			
			hp = mhp*currentHPPercentage
			mana = mhp*currentManaPercentage
			
			XPChanged.emit()

var weapon = "sword":
	set(value):
		weapon = value
		WeaponChanged.emit()

var weaponLevel = 0:
	set(value):
		weaponLevel = value
		WeaponUpgraded.emit()

var mhp = 3.0
var hp = mhp:
	set(value):
		hp = clamp(value, 0.0, mhp)
		HPChanged.emit()

var playerHitCount:int = 0

var atk = 1.0
var crit_rate = .05
var crit_dmg = 2.0

var mana = 0.0:
	set(value):
		mana = clamp(value, 0.0, mhp)
		ManaChanged.emit()

var manaRegen = .01

var piercing:bool
var naturalHealing:bool
var naturalMana:bool
var revenge:bool
var chasingProjectile:bool
var suddenDeath:bool
var secondChance:bool
var divineAid:bool
var tanky:bool
var smart:bool

var worlds = ["res://scenes/maps/map_forgottenTown.tscn"]

var enemiesID = [
	preload("res://objects/enemies/obj_espinhudo.tscn"),
	preload("res://objects/enemies/obj_sparkle.tscn"),
	preload("res://objects/enemies/obj_fatty.tscn"),
]

var waveData = {
	0: { 0: [0, 1] },
	1: { 0: [0, 3] },
	2: { 0: [0, 6] },
	3: { 0: [0, 9] },
	4: { 0: [0, 12] },
	5: { 0: [0, 18] },
	6: { 0: [0, 3], 1: [1, 1] },
	7: { 0: [0, 6], 1: [1, 3] },
	8: { 0: [0, 12], 1: [1, 8] },
	9: { 0: [0, 15], 1: [1, 12] },
	10: { 0: [0, 20], 1: [1, 17] },
	11: { 0: [0, 30], 1: [1, 25] },
	12: { 0: [0, 54], 1: [1, 43] },
	13: { 0: [0, 75], 1: [1, 22] },
	14: { 0: [0, 34], 1: [1, 88] },
	15: { 0: [0, 100], 1: [1, 50] },
	16: { 0: [0, 50], 1: [1, 5], 2: [2, 1] },
	17: { 0: [0, 70], 1: [1, 79], 2: [2, 5] },
	18: { 0: [0, 130], 1: [1, 90], 2: [2, 10] },
	19: { 0: [1, 100], 1: [2, 20] },
	20: { 0: [0, 140], 1: [1, 70], 2: [2, 25] },
	21: { 0: [0, 190], 1: [1, 120], 2: [2, 40] },
	22: { 0: [0, 250], 1: [1, 180], 2: [2, 50] },
}

var blessingsData = {
	0: {
		"name": "Melhore sua Arma",
		"repeatable": true,
		"weight": 35,
		"function":
	func():
	weaponLevel += 1
	if weaponLevel == 1: Game.blessingsData[0]["repeatable"] = false
	},
	
	1: {
		"name": "Benção da Cura",
		"desc": "Cura sua \"Vida\" em 100% da sua \"Vida Máxima\".",
		"texture_index": 0,
		"repeatable": true,
		"weight": 10,
		"function":
			func(): hp = mhp
	},
	
	2: {
		"name": "Benção da Vitalidade",
		"desc": "Aumenta sua \"Vida Máxima\" em 50%.",
		"texture_index": 1,
		"repeatable": true,
		"weight": 10,
		"function":
			func(): mhp *= 1.5
	},
	
	3: {
		"name": "Benção da Bruta Força",
		"desc": "Aumenta o \"Multiplicador de Ataque\" em 20%.",
		"texture_index": 2,
		"repeatable": true,
		"weight": 10,
		"function":
			func(): atk += .2
	},
	
	4: {
		"name": "Benção da Agilidade",
		"desc": "Aumenta a chance de \"Acerto Crítico\" em 5%.",
		"texture_index": 3,
		"repeatable": true,
		"weight": 8,
		"function":
			func(): crit_rate += .05
	},
	
	5: {
		"name": "Benção do Golpe Mortal",
		"desc": "Aumenta o dano causado por \"Acertos Críticos\" em 10%.",
		"texture_index": 4,
		"repeatable": true,
		"weight": 8,
		"function":
			func(): crit_dmg += .1
	},
	
	6: {
		"name": "Benção da Eficiência Arcana",
		"desc": "Aumenta a \"Eficiência da Regeneração de Mana\" em 2%.",
		"texture_index": 5,
		"repeatable": true,
		"weight": 8,
		"function":
			func(): manaRegen += .02
	},
	
	7: {
		"name": "Benção da Cura Natural",
		"desc": "Recupera 10% de sua vida máxima a cada 10 segundos.",
		"texture_index": 6,
		"repeatable": false,
		"weight": 5,
		"function":
			func(): naturalHealing = true
	},
	
	8: {
		"name": "Benção da Regeneração Espiritual",
		"desc": "Regenera mana naturalmente, a sua eficiência aumente de acordo com a sua \"Eficiência da Regeneração de Mana\".",
		"texture_index": 7,
		"repeatable": false,
		"weight": 5,
		"function":
			func(): naturalMana = true
	},
	
	9: {
		"name": "Benção da Penetração Letal",
		"desc": "Sua arma pode perfurar a através dos inimigos.",
		"texture_index": 8,
		"repeatable": false,
		"weight": 1,
		"function":
			func(): piercing = true
	},
	
	10: {
		"name": "Benção da Vingança Arcana",
		"desc": "Causa \"Dano Mágico\" ao inimigo com base na sua mana restante após sofrer dano.",
		"texture_index": 9,
		"repeatable": false,
		"weight": 2,
		"function":
			func(): revenge = true
	},
	
	11: {
		"name": "Benção do Tiro Perseguidor",
		"desc": "Dispara um projétil que persegue o inimigo com mais vida e causa dano igual ao seu ataque.",
		"texture_index": 10,
		"repeatable": false,
		"weight": 2,
		"function":
			func(): chasingProjectile = true
	},
	
	12: {
		"name": "Benção da Morte Súbita",
		"desc": "Caso morrer, você reviverá e terá o efeito de \"Ultima Chance\". Enquanto ativo, sua mana decairá rapidamente e você continuará vivo, recebendo um bonus de \"Dano Causado\" de 100%. Esse efeito dura até sua mana chegar a zero.",
		"texture_index": 11,
		"repeatable": false,
		"weight": 2,
		"function":
			func(): suddenDeath = true
	},
	
	13: {
		"name": "Benção da Segunda Chance",
		"desc": "Caso você morrer, você reviverá com 30% da sua vida máxima.",
		"texture_index": 12,
		"repeatable": false,
		"weight": 2,
		"function":
			func(): secondChance = true
	},
	
	14: {
		"name": "Benção da Ajuda Divina",
		"desc": "Invoca uma alma bondosa para lutar ao seu lado, com 50% do seu ataque, causando \"Dano Mágico\" aos inimigos. Enquanto estiver ativo, ela consumirá sua mana e desaparecerá após ela chegar a zero. Quando desaparecer, entrará em cooldown e ativará novamente após 30s e se sua mana for maior que 50% da sua vida máxima.",
		"texture_index": 13,
		"repeatable": false,
		"weight": 1,
		"function":
			func(): divineAid = true
	},
	
	15: {
		"name": "Benção da Dissipação Arcana",
		"desc": "O dano recebido por você é diminuido em 50%.",
		"texture_index": 14,
		"repeatable": false,
		"weight": 1,
		"function":
			func(): tanky = true
	},
	
	16: {
		"name": "Benção do Aprendizado Celestial",
		"desc": "Aumenta a experiência ganha após eliminar um inimigo em 50%.",
		"texture_index": 15,
		"repeatable": false,
		"weight": 1,
		"function":
			func(): smart = true
	},
}

var weaponsData = {
	"sword": [
		{
			"base_atk": 1.5,
			"texture_index": 0,
			"desc":
				"Com essa espada, \"Danos Críticos\" causam 50% a mais de dano que normalmente causariam."
		},
		
		{
			"base_atk": 1.8,
			"texture_index": 2,
			"desc":
				"Com essa melhoria, \"Danos Críticos\" causarão 100% a mais de dano que normalmente causariam."
		},
		
		{
			"base_atk": 2.5,
			"texture_index": 4,
			"desc":
				"Com essa melhoria, todos os danos causados pela espada serão duplicados."
		},
	],
	
	"saber": [
		{
			"base_atk": 1.0,
			"texture_index": 6,
			"desc":
				"Com esse sabre, o seu \"Dano Mágico\" é aumentado em 20% da sua mana."
		},
		{
			"base_atk": 1.2,
			"texture_index": 9,
			"desc":
				"Com essa melhoria, a mana perdida ao receber dano é diminuída em 75%."
		},
		{
			"base_atk": 1.5,
			"texture_index": 11,
			"desc":
				"Com essa melhoria, o multiplicador de \"Dano Mágico\" agora é de 150% da sua mana."
		},
	],
	
	"axe": [
		{
			"base_atk": 1.2,
			"texture_index": 12,
			"desc":
				"Com esse machado, toda vez que você perder vida, você receberá um bônus de \"Dano Causado\" de 10% permanentemente."
		},
		{
			"base_atk": 1.5,
			"texture_index": 14,
			"desc":
				"Com essa melhoria, agora você perde 75% a menos da sua vida."
		},
		{
			"base_atk": 2.0,
			"texture_index": 16,
			"desc":
				"Com essa melhoria, agora você sobrevive a um golpe fatal, ficando com 1 de vida. Esse efeito só pode aconter de novo após 60s ."
		},
	]
}

func _ready():
	var RNG = RandomNumberGenerator.new()
	
	print(RNG.get_seed())
	
	xp = 0
	
	add_child(trans)

func change_scene(scene:String, type:int=0):
	trans.transition(type)
	await trans.finishedIn
	get_tree().change_scene_to_file(scene)
	get_window().content_scale_size = Vector2(320, 180)
	await get_tree().process_frame
	SceneChangeCompleted.emit()
