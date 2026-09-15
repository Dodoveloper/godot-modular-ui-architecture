extends Node2D
## Bootstraps the demo's module graph and spawns DI-dependent scene content.
##
## Kept as a plain, non-module script per Godular's convention: [code]main.gd[/code] mounts and
## starts the root module before anything that resolves capabilities via
## [code]GdlrModuleManager.request()[/code] enters the tree (e.g. [Player], or the scene's
## [ViewRequester] node, which mounts the HUD through [CapGameUi] on its own [code]_ready[/code]).


const DemoModule = preload("res://demo/demo.md.gd")
const PlayerScene = preload("res://demo/modules/player/content/entities/player.tscn")


func _ready() -> void:
	await GdlrModuleManager.mount(DemoModule)
	await GdlrModuleManager.start()
	
	_spawn_player()


func _spawn_player() -> void:
	var player := PlayerScene.instantiate()
	player.global_position.x = 64
	add_child(player)
