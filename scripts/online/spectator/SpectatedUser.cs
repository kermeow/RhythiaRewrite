using Godot;
using Godot.Collections;
using Rhythia.Core.Online.Spectator;
using Rhythia.Core.Replays;

namespace Rhythia.Game;

public partial class SpectatedUser : GodotObject
{
    public string UserId;
    public string UserName;
    public bool Playing = false;
    public StreamInfo? Info;
    public GodotObject? Replay = (GodotObject)GD.Load<GDScript>("res://scripts/content/replays/Replay.gd").New();
    [Signal]
    public delegate void StreamStartedEventHandler();

    public SpectatedUser(string userId)
    {
        UserId = userId;
    }

    public void Cleanup() => Ended();

    public void Started(StreamInfo info)
    {
        Info = info;
        var syncFrame = (GodotObject)GD.Load<GDScript>("res://scripts/content/replays/frames/SyncFrame.gd").New();
        syncFrame.Set("time", info.SyncData.ReplayTime - 0.5);
        syncFrame.Set("sync_time", info.SyncData.SyncTime - 0.5);
        Replay ??= (GodotObject)GD.Load<GDScript>("res://scripts/content/replays/Replay.gd").New();
        Replay.Get("frames").AsGodotArray().Add(syncFrame);
        Replay.Set("mapset_id", info.MapId);
        Replay.Set("_mods", info.Mods);
        Replay.Set("_score", info.Score);
        Replay.Set("settings", info.Settings);
        Playing = true;
        EmitSignal(SignalName.StreamStarted);
    }

    public void Ended()
    {
        Info = null;
        Replay = null;
        Playing = false;
    }

    public void ProcessData(StreamData data)
    {
        Info.SyncData = data.SyncData;
        Info.Score = data.Score;
        if (Replay is null) return;
        var frames = new Array();
        foreach (var frame in data.Frames)
        {
            var gdFrame = Replay.Call("c_translate_frame", frame.Opcode, frame.Time, GD.Convert(frame.Data, Variant.Type.PackedByteArray));
            frames.Add(gdFrame);
        }
        var gdFrames = Replay.Get("frames").AsGodotArray();
        gdFrames.AddRange(frames);
        Replay.EmitSignal("frames_received", frames);
    }
}