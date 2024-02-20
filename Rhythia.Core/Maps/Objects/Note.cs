namespace Rhythia.Core.Maps.Objects;

[Serializable]
public class Note : IMapObject
{
    public double Time { get; set; }
    public double X { get; set; }
    public double Y { get; set; }
}