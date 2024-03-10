using Rhythia.Online;

namespace Rhythia.Maps;

[Serializable]
public class MapSetInfo : IHasOnlineId<int>
{
    public int OnlineId { get; set; } = 0;
    public List<MapInfo> Maps { get; set; } = new();
    public MapMetadata Metadata => Maps.FirstOrDefault()?.Metadata ?? new();
}