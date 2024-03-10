using System;
using System.Collections.Generic;
using Rhythia.Online;

namespace Rhythia.Maps
{
    [Serializable]
    public class MapInfo : IHasOnlineId<int>
    {
        public int OnlineId { get; set; } = 0;
        public MapSetInfo? MapSet { get; set; }
        public string Name { get; set; } = string.Empty;
        public List<string> Mappers { get; set; } = new();
        public string Mapper => string.Join(", ", Mappers);
        public MapMetadata Metadata { get; set; } = new();
        public string File { get; set; } = string.Empty;
    }
}