extends Node

const MP_VERSION = 1

var lobby:Lobby

var player_name:String = "Player"
var player_color:Color = Color(1,1,1,1)

@onready var api:SceneMultiplayer = get_tree().get_multiplayer()
@onready var peer:MultiplayerPeer = ENetMultiplayerPeer.new()

func mp_print(string):
	print("%s:" % api.get_unique_id(),string)

func _ready():
	api.auth_callback = auth_callback
	api.peer_authenticating.connect(peer_authenticating)
	api.peer_authentication_failed.connect(peer_auth_failed)
	
	api.connected_to_server.connect(connected)
	api.server_disconnected.connect(disconnected)
	
	api.peer_connected.connect(peer_added)
	api.peer_disconnected.connect(peer_removed)

func check_connected():
	return peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED

func host(port:int=12345) -> Error:
	if check_connected():
		peer.close()
	var err = peer.create_server(port)
	mp_print("Hosting a server on port %s" % port)
	api.multiplayer_peer = peer
	if err == OK:
		connected()
		local_player = lobby.create_player(1)
		local_player.nickname = player_name
		local_player.color = player_color
	return err
func join(address:String="127.0.0.1",port:int=12345) -> Error:
	if check_connected():
		peer.close()
	var err = peer.create_client(address,port)
	mp_print("Joining a server on port %s" % port)
	api.multiplayer_peer = peer
	return err
func leave():
	peer.close()

var local_player:Player
func send_auth(id:int):
	var packet = PackedByteArray()
	packet.resize(128)
	var player_data = {
		nickname = player_name,
		color = player_color
	}
	packet.encode_u8(0,MP_VERSION)
	packet.encode_var(1,player_data)
	api.send_auth(id,packet)
func auth_callback(id:int,data:PackedByteArray):
	mp_print("Received auth packet")
	if id == 1:
		var version = data.decode_u8(0)
		if version != MP_VERSION:
			peer.close()
			return
		api.complete_auth(1)
		return
	if !api.is_server(): return
	var player_data:Dictionary = data.decode_var(1)
	var player = lobby.create_player(id)
	player.nickname = player_data.get("nickname","Player")
	player.color = player_data.get("color",Color.WHITE)
	api.complete_auth(id)

func connected():
	mp_print("Connected to a server")
	lobby = preload("res://prefabs/multi/Lobby.tscn").instantiate()
	add_child(lobby)
func disconnected():
	mp_print("Disconnected from server")
	lobby.queue_free()

func peer_authenticating(id:int):
	mp_print("Peer attempting to connect %s" % id)
	send_auth(id)
func peer_auth_failed(id:int):
	mp_print("Peer failed to connect %s" % id)
func peer_added(id:int):
	mp_print("Peer connected %s" % id)
func peer_removed(id:int):
	mp_print("Peer disconnected %s" % id)