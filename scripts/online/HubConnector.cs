using System;
using Godot;
using Microsoft.AspNetCore.SignalR.Client;
using Microsoft.Extensions.DependencyInjection;

namespace Rhythia.Game;

public class HubConnector
{
    public static string BaseAddress => Online.MasterServer;
    public Action<HubConnection>? ConfigureConnection;
    public HubConnection? CurrentConnection;
    public readonly string Endpoint;

    public HubConnector(string endpoint)
    {
        Endpoint = endpoint;
    }

    public HubConnectionState AttemptConnect()
    {
        CurrentConnection ??= buildConnection();
        if (CurrentConnection.State != HubConnectionState.Disconnected)
            throw new InvalidOperationException("Already connected/connecting");
        CurrentConnection.StartAsync().Wait();
        return CurrentConnection.State;
    }

    private HubConnection buildConnection()
    {
        var builder = new HubConnectionBuilder()
            .WithUrl(BaseAddress.PathJoin(Endpoint), options =>
            {
                options.Headers.Add("Discord", DiscordWrapper.OAuthToken!);
            });
        builder.AddMessagePackProtocol();
        
        var connection = builder.Build();
        ConfigureConnection?.Invoke(connection);
        return connection;
    }
}