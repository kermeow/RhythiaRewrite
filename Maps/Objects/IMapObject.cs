using System;
using Newtonsoft.Json;

namespace Rhythia.Maps.Objects
{
    [JsonObject(MemberSerialization.OptIn)]
    public interface IMapObject
    {
        double Time { get; set; }
    }
}