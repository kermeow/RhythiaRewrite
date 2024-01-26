using System.Net;
using System.Threading;
using System.Threading.Tasks;
using Discord;
using Godot;
using Godot.Collections;
using Microsoft.AspNetCore.SignalR.Client;
using Rhythia.Core.Online.Spectator;
using Rhythia.Core.Replays;

namespace Rhythia.Game;

public partial class Online : Node
{
    public static Online Instance { get; private set; }

    public Online()
    {
        Instance = this;
    }

    public static bool Connected { get; private set; } = false;
    public static string ConnectMessage { get; private set; } = "No attempt made to connect";
    public static string UserId { get; private set; }
    public static string UserName { get; private set; }

    public static string MasterServer => ProjectSettings
        .GetSettingWithOverride("application/networking/multiplayer/master_server").AsString();
    public static string StatusEndpoint => ProjectSettings
        .GetSettingWithOverride("application/networking/multiplayer/status_endpoint").AsString();

    public static SpectatorClient SpectatorClient = new();
    public static bool AttemptConnect()
    {
        GD.Print("Attempting connection");
        var attempt = attemptConnect();
        attempt.Wait();
        var authenticated = attempt.Result;
        if (authenticated)
            SpectatorClient.AttemptConnect();
        Connected = authenticated && SpectatorClient.State == HubConnectionState.Connected;
        GD.Print($"Connected?: {Connected} | Message: {ConnectMessage} | Spectate: {SpectatorClient.State}");
        return attempt.Result;
    }

    public static bool AttemptConnectRetry(int retries = 3)
    {
        var firstAttempt = AttemptConnect();
        if (firstAttempt) return true;
        var result = false;
        for (int i = 0; i < retries; i++)
        {
            Thread.Sleep(1000);
            GD.Print($"Failed to connect - retrying ({i+1}/{retries})");
            result = AttemptConnect();
            if (result) break;
        }
        return result;
    }
    private static async Task<bool> attemptConnect()
    {
        ConnectMessage = "Unknown error";
        DiscordWrapper.AttemptGetOAuthToken();
        if (!DiscordWrapper.Connected || DiscordWrapper.OAuthToken is null)
        {
            ConnectMessage = $"Discord not connected - {DiscordWrapper.Connected},{DiscordWrapper.OAuthToken}";
            return false;
        }
        if (DiscordWrapper.User is null) return false;
        User user = DiscordWrapper.UserManager.GetCurrentUser();
        UserId = user.Id.ToString();
        UserName = user.Username;
        using var client = new System.Net.Http.HttpClient();
        client.DefaultRequestHeaders.Add("Discord", DiscordWrapper.OAuthToken);
        var response = await client.GetAsync(StatusEndpoint);
        var result = await response.Content.ReadAsStringAsync();
        ConnectMessage = result;
        var status = response.StatusCode;
        GD.Print($"Got {status}: {result}");
        return response.IsSuccessStatusCode;
    }

    public override void _Ready()
    {
        GetNode("/root/Rhythia").Connect("on_init_complete", new Callable(this, nameof(GDConnect)));
    }

    public override void _ExitTree()
    {
        SpectatorClient.AttemptDisconnect();
    }

    public void GDConnect() => Task.Run(() => AttemptConnectRetry());

    public void GDStartStreaming(GodotObject replay)
    {
        var info = new StreamInfo();
        info.MapId = replay.Get("mapset_id").AsString();
        info.Mods = replay.Get("_mods").AsByteArray();
        info.Score = replay.Get("_score").AsByteArray();
        info.Settings = replay.Get("settings").AsByteArray();
        info.SyncData = new StreamSyncData()
        {
            ReplayTime = 0,
            SyncTime = -1
        };
        SpectatorClient.StartStreaming(info);
    }
    public void GDSendStreamData(GodotObject replay, Array frames, float replayTime, float syncTime)
    {
        var streamData = new StreamData();
        streamData.Score = replay.Get("_score").AsByteArray();
        var syncData = new StreamSyncData();
        syncData.ReplayTime = replayTime;
        syncData.SyncTime = syncTime;
        streamData.SyncData = syncData;
        var packedFrames = new ReplayFrame[frames.Count];
        for (int i = 0; i < frames.Count; i++)
        {
            var frame = (GodotObject)frames[i];
            var packedFrame = new ReplayFrame();
            packedFrame.Opcode = replay.Call("get_opcode_for", frame).AsInt32();
            packedFrame.Time = frame.Get("time").AsDouble();
            packedFrame.Data = frame.Call("_encode").AsByteArray();
            packedFrames[i] = packedFrame;
        }
        streamData.Frames = packedFrames;
        SpectatorClient.SendStreamData(streamData);
    }
    public void GDStopStreaming()
    {
        SpectatorClient.StopStreaming();
    }
}