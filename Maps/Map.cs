using System.Collections.Immutable;
using Rhythia.Maps.Objects;

namespace Rhythia.Maps;

[Serializable]
public class Map
{
    public MapInfo Info { get; set; } = new();
    public MapMetadata Metadata => Info.Metadata;
    public List<IMapObject> Objects { get; set; } = new();
    public int ObjectCount => Objects.Count;
    public IImmutableList<Note> Notes => Objects.OfType<Note>().ToImmutableList();
    public int NoteCount => Notes.Count;
}