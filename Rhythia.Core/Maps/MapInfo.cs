using System.Text.Json.Serialization;
using Rhythia.Core.Online;

namespace Rhythia.Core.Maps;

[Serializable]
public class MapInfo : IHasOnlineId<int>
{
    public int OnlineId { get; set; } = 0;
    public string Name { get; set; } = string.Empty;
    public List<string> Mappers { get; set; } = new();
    public string Mapper => string.Join(", ", Mappers);
    public MapMetadata Metadata { get; set; } = new();
    [JsonIgnore]
    public string Path { get; set; } = string.Empty;
}