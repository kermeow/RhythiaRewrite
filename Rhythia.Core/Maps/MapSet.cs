namespace Rhythia.Core.Maps;

public class MapSet : IMapSet
{
    public MapSetMetadata Metadata { get; set; }
    public List<IMap> Maps { get; set; } = new();
    public string Path { get; set; } = string.Empty;
    public List<string> Files { get; set; } = new();
    public MapSet()
    {
        Metadata = new MapSetMetadata
        {
            Title = "Unknown",
            Artist = "Unknown"
        };
    }
}