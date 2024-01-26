using System;
using System.Threading.Tasks;
using Godot;
using Microsoft.AspNetCore.SignalR.Client;

namespace Rhythia.Game;

public class HubClient
{
    public bool Connected { get; private set; } = false;
    private HubConnector connector;
    protected HubConnection? connection => connector?.CurrentConnection;
    public HubConnectionState? State => connection?.State;

    public HubClient(string endpoint)
    {
        connector = new(endpoint);
        connector.ConfigureConnection = ConfigureConnection;
    }

    public HubConnectionState AttemptConnect()
    {
        return connector.AttemptConnect();
    }

    public HubConnectionState AttemptDisconnect()
    {
        connection!.StopAsync().Wait();
        return connection.State;
    }

    public virtual void ConfigureConnection(HubConnection connection)
    {}
}