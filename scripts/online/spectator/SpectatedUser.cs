using Godot;
using Godot.Collections;
using Rhythia.Core.Online.Spectator;
using Rhythia.Core.Replays;

namespace Rhythia.Game;

public class SpectatedUser
{
    public string UserId;
    public bool Playing = false;
    public StreamInfo? Info;
    public GodotObject? Replay;

    public SpectatedUser(string userId)
    {
        UserId = userId;
    }

    public void Cleanup() => Ended();

    public void Started(StreamInfo info)
    {
        Info = info;
        Replay = (GodotObject)GD.Load<GDScript>("res://scripts/content/replays/Replay.gd").New();
        Playing = true;
    }

    public void Ended()
    {
        Info = null;
        Replay?.Free();
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

        var syncFrame = (GodotObject)GD.Load<GDScript>("res://scripts/content/replays/frames/SyncFrame.gd").New();
        syncFrame.Set("time", data.SyncData.ReplayTime);
        syncFrame.Set("sync_time", data.SyncData.SyncTime);
        frames.Add(syncFrame);
        var gdFrames = Replay.Get("frames").AsGodotArray();
        gdFrames.AddRange(frames);
        Replay.EmitSignal("frames_received", frames);
    }
}