extends Object
class_name MapsetLoader

const CACHE_VERSION = 1

var registry:Registry
func _init(_registry:Registry):
	registry = _registry

func load_from_folder(folder:String):
	if !DirAccess.dir_exists_absolute(folder):
		return
	var dir = DirAccess.open(folder)

	var _start_at = Time.get_ticks_usec()

	# Get cached list
	var cache = {}
	var cache_exists = FileAccess.file_exists(folder.path_join(".cache"))
	if cache_exists:
		var cache_file = FileAccess.open(folder.path_join(".cache"),FileAccess.READ)
		cache = JSON.parse_string(cache_file.get_as_text())
		cache_file.close()
		if cache.get("v",0) != CACHE_VERSION:
			cache = {}

	# Load maps
	var maps = []
	for file in dir.get_files():
		var extension = file.get_extension()
		if extension != "sspm" and extension != "rhym": continue
		var _start = Time.get_ticks_usec()
		var full_path = folder.path_join(file)
		var mapset:Mapset
		if file in cache.keys():
			var cached_mapset = cache[file]
			mapset = Mapset.new()
			mapset.format = 3
			mapset.id = cached_mapset.id
			mapset.name = cached_mapset.name
			mapset.creator = cached_mapset.creator
			mapset.online_id = cached_mapset.online_id
			mapset.maps = cached_mapset.maps.map(
				func(cached_map):
					var map = Map.new()
					map.id = cached_map[0]
					map.name = cached_map[1]
					return map
			)
			mapset.file_offsets = cached_mapset.file_offsets
			mapset.length = cached_mapset.length
			var _end = Time.get_ticks_usec()
			if Globals.debug: print("Loaded v3 map from cache in %sms" % [(_end-_start)/1000.0])
		else:
			mapset = Mapset.read_from_file(full_path)
			var _end = Time.get_ticks_usec()
			if Globals.debug: print("Loaded v%s map from file in %sms" % [mapset.format,(_end-_start)/1000.0])
		mapset.path = full_path
		maps.append(mapset)

	# Save cached maps
	var _cache_start = Time.get_ticks_usec()
	var new_cache = {}
	new_cache.v = CACHE_VERSION
	for mapset in maps:
		if mapset.format != 3: continue
		var file = mapset.path.get_file()
		new_cache[file] = {
			id = mapset.id,
			name = mapset.name,
			creator = mapset.creator,
			online_id = mapset.online_id,
			maps = mapset.maps.map(
				func(map): return [map.id, map.name]
			),
			file_offsets = mapset.file_offsets,
			length = mapset.length
		}
	var cache_file = FileAccess.open(folder.path_join(".cache"),FileAccess.WRITE)
	cache_file.store_string(JSON.stringify(new_cache,"",false))
	cache_file.close()
	var _cache_end = Time.get_ticks_usec()
	if Globals.debug: print("Took %sms to save new cache" % [(_cache_end-_cache_start)/1000.0])

	# Load maps into registry
	for map in maps:
		registry.add_item(map)

	var _end_at = Time.get_ticks_usec()
	print("Loaded %s maps in %sms" % [maps.size(),(_end_at-_start_at)/1000.0])
