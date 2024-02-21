using System.Collections.Immutable;
using System.Text.Json.Serialization;
using Microsoft.VisualBasic;
using Rhythia.Core.Maps.Objects;
using Rhythia.Core.Online;

namespace Rhythia.Core.Maps;

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