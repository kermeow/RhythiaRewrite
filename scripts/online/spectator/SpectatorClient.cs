using System.Collections.Generic;
using System.Threading.Tasks;
using Godot;
using Microsoft.AspNetCore.SignalR.Client;
using Rhythia.Core.Online.Spectator;

namespace Rhythia.Game;

public class SpectatorClient : HubClient, ISpectatorClient, ISpectatorServer
{
    public SpectatedUser Self = new("Self");
    public Dictionary<string, SpectatedUser> WatchingUsers = new();
    public SpectatorClient() : base("spectator")
    {
    }

    public override void ConfigureConnection(HubConnection connection)
    {
        connection.On<string, string>(nameof(PlayerAdded), PlayerAdded);
        connection.On<string>(nameof(PlayerRemoved), PlayerRemoved);
        connection.On<string, StreamData>(nameof(StreamDataReceived), StreamDataReceived);
        connection.On<string, StreamInfo>(nameof(StreamStarted), StreamStarted);
        connection.On<string>(nameof(StreamEnded), StreamEnded);
    }

    public async Task PlayerAdded(string userId, string userName)
    {
        GD.Print($"Player added! {userId} {userName}");
        Online.Instance.SpectatePlayerNames[userId] = userName;
        Online.Instance.SpectatePlayerMaps[userId] = "N/A";
    }

    public async Task PlayerRemoved(string userId)
    {
        GD.Print($"Player removed! {userId}");
        Online.Instance.SpectatePlayerNames.Remove(userId);
        Online.Instance.SpectatePlayerMaps.Remove(userId);
    }

    public Task StartStreaming(StreamInfo streamInfo)
    {
        Self.Started(streamInfo);
        return connection!.SendAsync(nameof(StartStreaming), streamInfo);
    }

    public Task StopStreaming()
    {
        Self.Ended();
        return connection!.SendAsync(nameof(StopStreaming));
    }

    public Task SendStreamData(StreamData streamData)
    {
        Self.ProcessData(streamData);
        return connection!.SendAsync(nameof(SendStreamData), streamData);
    }

    public Task StartWatching(string userId)
    {
        var user = new SpectatedUser(userId);
        WatchingUsers.Add(userId, user);
        return connection!.SendAsync(nameof(StartWatching), userId);
    }

    public Task StopWatching(string userId)
    {
        if (WatchingUsers.TryGetValue(userId, out var user))
            user.Cleanup();
        WatchingUsers.Remove(userId);
        return connection!.SendAsync(nameof(StopWatching), userId);
    }

    public async Task StreamDataReceived(string userId, StreamData streamData)
    {
        var exists = WatchingUsers.TryGetValue(userId, out var user);
        if (!exists || user is null) return;
        user.ProcessData(streamData);
    }

    public async Task StreamStarted(string userId, StreamInfo streamInfo)
    {
        Online.Instance.SpectatePlayerNames[userId] = streamInfo.UserName ?? "unknown";
        Online.Instance.SpectatePlayerMaps[userId] = streamInfo.MapId ?? "unknown";
        var exists = WatchingUsers.TryGetValue(userId, out var user);
        if (!exists || user is null) return;
        user.Started(streamInfo);
    }

    public async Task StreamEnded(string userId)
    {
        Online.Instance.SpectatePlayerMaps[userId] = "N/A";
        var exists = WatchingUsers.TryGetValue(userId, out var user);
        if (!exists || user is null) return;
        user.Ended();
    }
}