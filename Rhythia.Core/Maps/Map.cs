using System.Collections.Immutable;
using Rhythia.Core.Maps.Objects;

namespace Rhythia.Core.Maps;

public class Map
{
    public MapMetadata Metadata { get; set; }
    public List<IMapObject> Objects { get; set; } = new();
    public int ObjectCount => Objects.Count;
    public IReadOnlyList<Note> Notes => Objects.OfType<Note>().ToImmutableList();
    public int NoteCount => Notes.Count;
    
    public Map()
    {
        Metadata = new MapMetadata
        {
            Name = "Unknown",
            Author = "Unknown"
        };
    }
}