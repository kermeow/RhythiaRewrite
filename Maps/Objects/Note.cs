using System;
using Newtonsoft.Json;

namespace Rhythia.Maps.Objects
{
    [Serializable, JsonObject]
    public class Note : IMapObject
    {
        public double Time { get; set; }
        public double X { get; set; }
        public double Y { get; set; }
    }
}