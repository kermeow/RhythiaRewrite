using MessagePack;
using Rhythia.Core.Maps;

namespace Rhythia.Core.Users;

[Serializable]
[MessagePackObject]
[Union(10, typeof(Idle))]
[Union(11, typeof(Playing))]
// [Union(12, typeof(Replaying))]
public abstract class UserActivity
{
    public abstract string Status { get; }
    public virtual string? Details => null;

    [MessagePackObject]
    public class Idle : UserActivity
    {
        public override string Status => "Listening to music";
    }
    [MessagePackObject]
    public class Playing : UserActivity
    {
        [Key(0)] public int MapId { get; set; }
        [Key(1)] public string MapDisplayName { get; set; }
        public override string Status => "Playing a map";
        public override string? Details => MapDisplayName;

        public Playing(Map map)
        {
            MapId = map.Info.OnlineId;
            MapDisplayName = map.Metadata.FriendlyName;
        }
    }
    // [MessagePackObject]
    // public class Replaying : UserActivity
    // {
    //     [Key(0)] public int MapId { get; set; }
    //     [Key(1)] public string MapDisplayName { get; set; }
    //     public override string Status => "Watching a replay";
    //     public override string? Description => MapDisplayName;
    //
    //     public Replaying(MapMetadata mapMetadata)
    //     {
    //         MapId = 0;
    //         MapDisplayName = mapMetadata.FriendlyName;
    //     }
    // }
}