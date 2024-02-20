namespace Rhythia.Core.Maps;

public class MapSet
{
    public string FilePath;
    public MapSetMetadata Metadata;
    public List<Map> Maps = new();

    public MapSet()
    {
        Metadata = new MapSetMetadata
        {
            Title = "Unknown",
            Artist = "Unknown"
        };
    }
}