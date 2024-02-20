using Rhythia.Core.Maps.Objects;

namespace Rhythia.Core.Maps;

public interface IMap
{
    MapMetadata Metadata { get; set; }
    List<IMapObject> Objects { get; set; }
    int ObjectCount { get; }
    IReadOnlyList<Note> Notes { get; }
    int NoteCount { get; }
}