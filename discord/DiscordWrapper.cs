using System;
using Godot;
using Discord;

namespace Rhythia.Game;

public partial class DiscordWrapper : Node
{
    public const long ClientId = 1066457505246486598;
    public const ulong ClientFlags = (ulong)Discord.CreateFlags.NoRequireDiscord;
    
    public static Discord.Discord Core;
    public static ActivityManager ActivityManager => Core.GetActivityManager();
    public static ApplicationManager ApplicationManager => Core.GetApplicationManager();

    public void SetActivity(string state, string details, bool instance)
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
            Party =
            {
                Id = Online.UserId,
                Privacy = ActivityPartyPrivacy.Public
            },
            Secrets =
            {
                Join = $"join {Online.UserId}"
            },
            Instance = instance
        };
        GD.Print(Online.UserId);
        if (OS.HasFeature("debug")) GD.Print($"State: {state} | Details: {details} | Instance: {instance}");
        if (Core == null) return;
        try
        {
            ActivityManager.UpdateActivity(activity, (result) =>
            {
                GD.Print(result);
            });
        }
        catch (ResultException exception)
        {
            resultError(exception);
        }
    }
    
    private Timer _callbackTimer;
    public override void _Ready()
    {
        try
        {
            GD.Print("Trying to create Discord Core");
            Core = new Discord.Discord(ClientId, ClientFlags);
            GD.Print("Created Discord Core");
            GD.Print("Trying to setup Discord Core");
            var executablePath = OS.GetExecutablePath();
            ActivityManager.RegisterCommand(executablePath);
            ActivityManager.OnActivityJoin += onActivityJoin;
            GD.Print("Finished setting up Discord Core");
        }
        catch (Exception exception)
        {
            GD.Print($"Failed to create Discord Core: {exception}");
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

    private void onActivityJoin(string secret)
    {
        GD.Print($"Attempt to join with secret {secret}");
    }

    private void resultError(ResultException exception)
    {
        if (exception.Result == Result.NotRunning)
        {
            GD.Print("Discord isn't running");
            disable();
        }
        else
            GD.Print($"Discord Error: {nameof(exception.Result)}");
    }

    private void runCallbacks()
    {
        try
        {
            Core.RunCallbacks();
        }
        catch (ResultException exception)
        {
            resultError(exception);
        }
    }

    private void disable()
    {
        _callbackTimer.Dispose();
        Core.Dispose();
    }
}
