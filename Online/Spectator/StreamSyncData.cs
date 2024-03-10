using MessagePack;

namespace Rhythia.Online.Spectator;

[MessagePackObject]
public class StreamSyncData
{
    [Key(0)] public double ReplayTime { get; set; }
    [Key(1)] public double SyncTime { get; set; }
}