namespace Rhythia.Core.Maps;

public interface IMapSet
{
    MapSetMetadata Metadata { get; set; }
    List<IMap> Maps { get; set; }
}