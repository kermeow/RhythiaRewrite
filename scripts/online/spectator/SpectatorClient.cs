using System.Collections.Generic;
using System.Threading.Tasks;
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
        connection.On<string, StreamData>(nameof(StreamDataReceived), StreamDataReceived);
        connection.On<string, StreamInfo>(nameof(StreamStarted), StreamStarted);
        connection.On<string>(nameof(StreamEnded), StreamEnded);
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
        var exists = WatchingUsers.TryGetValue(userId, out var user);
        if (!exists || user is null) return;
        user.Started(streamInfo);
    }

    public async Task StreamEnded(string userId)
    {
        var exists = WatchingUsers.TryGetValue(userId, out var user);
        if (!exists || user is null) return;
        user.Ended();
    }
}