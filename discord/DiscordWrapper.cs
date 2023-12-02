using System;
using Godot;
using Discord;

public partial class DiscordWrapper : Node
{
    public const long ClientId = 1066457505246486598;
    public const ulong ClientFlags = (ulong)Discord.CreateFlags.NoRequireDiscord;
    
    public Discord.Discord Core;
    public ActivityManager ActivityManager => Core.GetActivityManager();

    public void SetActivity(string state, string details, bool instance = false)
    {
        var activity = new Activity
        {
            State = state,
            Details = details,
            Assets =
            {
                LargeImage = "icon-bg",
                LargeText = "Rhythia Rewrite"
            },
            Instance = instance
        };
        if (OS.HasFeature("debug"))
        {
            GD.Print($"State: {state} | Details: {details} | Instance: {instance}");
        }
        try {ActivityManager.UpdateActivity(activity, (result) => {});} catch (Exception) {}
    }
    
    private Timer _callbackTimer;
    public override void _Ready()
    {
        try
        {
            GD.Print("Trying to create Discord Core");
            Core = new Discord.Discord(ClientId, ClientFlags);
            GD.Print("Created Discord Core");
        }
        catch (Exception exception)
        {
            GD.Print($"Failed to create Discord Core: {exception.Message}");
            return;
        }

        _callbackTimer = new();
        _callbackTimer.OneShot = false;
        _callbackTimer.Autostart = true;
        _callbackTimer.WaitTime = 1 / 30.0;
        _callbackTimer.ProcessMode = ProcessModeEnum.Always;
        _callbackTimer.Timeout += runCallbacks;
        AddChild(_callbackTimer);
    }

    public override void _ExitTree()
    {
        disable();
    }

    private void runCallbacks()
    {
        try
        {
            Core.RunCallbacks();
        }
        catch (ResultException exception)
        {
            if (exception.Result == Result.NotRunning)
            {
                GD.Print("Discord isn't running");
                disable();
            }
            else
                GD.Print($"Discord Error: {nameof(exception.Result)}");
        }
    }

    private void disable()
    {
        _callbackTimer.Dispose();
        Core.Dispose();
    }
}