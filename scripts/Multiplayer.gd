extends Node

const MP_VERSION = 3
const MP_PORT = 12345

var lobby:Lobby
var server_ip:String

var player_name:String = "Player"
var player_color:Color = Color(1,1,1,1)

@onready var api:SceneMultiplayer = get_tree().get_multiplayer()
@onready var peer:ENetMultiplayerPeer = ENetMultiplayerPeer.new()
@onready var upnp:UPNP = UPNP.new()

func mp_print(string):
	print("%s : " % api.get_unique_id(),string)

func _ready():
	upnp.discover()
	
	api.auth_callback = auth_callback
	api.peer_authenticating.connect(peer_authenticating)
	api.peer_authentication_failed.connect(peer_auth_failed)
	
	api.connected_to_server.connect(connected)
	api.server_disconnected.connect(disconnected)
	
	api.peer_connected.connect(peer_added)
	api.peer_disconnected.connect(peer_removed)

func check_connected():
	return lobby and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

func host(port:int=MP_PORT) -> Error:
	if check_connected():
		peer.close()
	var err = peer.create_server(port)
	mp_print("Hosting a server on port %s" % port)
	api.multiplayer_peer = peer
	server_ip = upnp.query_external_address()
	if err == OK:
		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
			print(upnp.add_port_mapping(MP_PORT,MP_PORT,"Sound Space Plus","UDP",3600))
			print(upnp.add_port_mapping(MP_PORT,MP_PORT,"Sound Space Plus","TCP",3600))
		create_lobby()
		lobby.create_player(1,player_name,player_color)
	return err
func join(address:String="127.0.0.1",port:int=MP_PORT) -> Error:
	if check_connected():
		peer.close()
	var err = peer.create_client(address,port)
	server_ip = address
	mp_print("Joining a server %s on port %s" % [address,port])
	api.multiplayer_peer = peer
	return err
func leave():
	if api.is_server():
		upnp.delete_port_mapping(MP_PORT,"UDP")
		upnp.delete_port_mapping(MP_PORT,"TCP")
	peer.close()

var local_player:Player:
	get:
		if lobby.players: return lobby.players.get(api.get_unique_id())
		return null

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
	var nickname = player_data.get("nickname","Player")
	var color = player_data.get("color",Color.WHITE)
	lobby.create_player(id,nickname,color)
	api.complete_auth(id)

func create_lobby():
	mp_print("Connected to a server")
	get_tree().paused = true
	lobby = preload("res://prefabs/multi/Lobby.tscn").instantiate()
	lobby.set_multiplayer_authority(1)
	add_child(lobby)
	get_tree().paused = false

func connected():
	mp_print("Connected to a server")
	create_lobby()
func disconnected():
	mp_print("Disconnected from server")
	get_tree().paused = true
	lobby.queue_free()
	lobby = null
	get_tree().paused = false

func peer_authenticating(id:int):
	mp_print("Peer attempting to connect %s" % id)
	send_auth(id)
func peer_auth_failed(id:int):
	mp_print("Peer failed to connect %s" % id)
func peer_added(id:int):
	mp_print("Peer connected %s" % id)
func peer_removed(id:int):
	mp_print("Peer disconnected %s" % id)
	if api.is_server(): lobby.players[id].queue_free()
	elif id == 1: peer.close()
