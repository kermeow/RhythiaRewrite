extends Object
class_name MapsetLoader

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
	
	# Load maps
	var maps = []
	for file in dir.get_files():
		if file.get_extension() != "sspm": continue
		var full_path = folder.path_join(file)
		var md5 = FileAccess.get_md5(full_path)
		var mapset:Mapset
		if md5 in cache.keys():
			var cached_mapset = cache[md5]
			mapset = Mapset.new()
			mapset.id = md5
			mapset.name = cached_mapset.name
			mapset.creator = cached_mapset.creator
			mapset.online_id = cached_mapset.online_id
			mapset.format = cached_mapset.format
			mapset.maps = cached_mapset.maps.map(
				func(cached_map):
					var map = Map.new()
					map.id = cached_map[0]
					map.name = cached_map[1]
					return map
			)
		else:
			mapset = MapsetReader.read_from_file(full_path)
		mapset.path = full_path
		maps.append(mapset)
	
	# Save cached maps
	var new_cache = {}
	for mapset in maps:
		new_cache[mapset.id] = {
			name = mapset.name,
			creator = mapset.creator,
			online_id = mapset.online_id,
			format = mapset.format,
			maps = mapset.maps.map(func(map): return [map.id,map.name])
		}
	var cache_file = FileAccess.open(folder.path_join(".cache"),FileAccess.WRITE)
	cache_file.store_string(JSON.stringify(new_cache,"",false))
	cache_file.close()
	
	# Load maps into registry
	for map in maps:
		registry.add_item(map)
	
	var _end_at = Time.get_ticks_usec()
	
	print("Loaded %s maps in %sms" % [maps.size(),(_end_at-_start_at)/1000.0])
