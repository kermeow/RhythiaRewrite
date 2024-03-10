using Godot;
using Godot.Collections;
using Rhythia.Online.Spectator;
using Rhythia.Replays;

namespace Rhythia.Online.Spectator
{
    public partial class SpectatedUser : GodotObject
    {
        public string UserId;
        public string UserName = "Someone";
        public bool Playing = false;
        public StreamInfo? Info;
        public GodotObject? Replay = (GodotObject)GD.Load<GDScript>("res://scripts/content/replays/Replay.gd").New();
        [Signal]
        public delegate void StreamStartedEventHandler();
        [Signal]
        public delegate void StreamEndedEventHandler();

        public SpectatedUser(string userId)
        {
            UserId = userId;
        }

        public void Cleanup() => Ended();

        public void Started(StreamInfo info)
        {
            Info = info;
            var syncFrame = (GodotObject)GD.Load<GDScript>("res://scripts/content/replays/frames/SyncFrame.gd").New();
            syncFrame.Set("time", info.SyncData.ReplayTime);
            syncFrame.Set("sync_time", info.SyncData.SyncTime);
            Replay = (GodotObject)GD.Load<GDScript>("res://scripts/content/replays/Replay.gd").New();
            Replay.Get("frames").AsGodotArray().Add(syncFrame);
            Replay.Set("player_name", info.UserName ?? UserName);
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
            EmitSignal(SignalName.StreamEnded);
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
}