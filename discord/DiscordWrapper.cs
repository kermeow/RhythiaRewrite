using System;
using System.Threading;
using System.Threading.Tasks;
using Godot;
using Discord;
using Timer = Godot.Timer;

namespace Rhythia.Game;

public partial class DiscordWrapper : Node
{
    public static bool Connected = false; 
    public const long ClientId = 1066457505246486598;
    public const ulong ClientFlags = (ulong)Discord.CreateFlags.NoRequireDiscord;
    
    public static Discord.Discord? Core;
    public static ActivityManager ActivityManager => Core!.GetActivityManager();
    public static ApplicationManager ApplicationManager => Core!.GetApplicationManager();
    public static UserManager UserManager => Core!.GetUserManager();
    public static string? OAuthToken;
    public static User? User;

    public void SetActivity(string state, string details, bool instance)
    {
        if (!Connected) return;
        var userId = (User?.Id ?? 0).ToString();
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
                Id = userId,
                Privacy = ActivityPartyPrivacy.Public
            },
            Secrets =
            {
                Join = $"spec {userId}"
            },
            Instance = instance
        };
        if (OS.HasFeature("debug")) GD.Print($"State: {state} | Details: {details} | Instance: {instance}");
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
    
    private Timer _callbackTimer = new();
    public override async void _Ready()
    {
        try
        {
            GD.Print("Trying to create Discord Core");
            Core = new Discord.Discord(ClientId, ClientFlags);
            runCallbacks();
            var executablePath = OS.GetExecutablePath();
            ActivityManager.RegisterCommand(executablePath);
            ActivityManager.OnActivityJoin += onActivityJoin;
            ApplicationManager.GetOAuth2Token((Result result, ref OAuth2Token token) =>
            {
                if (result != Result.Ok)
                {
                    GD.Print("Couldn't get OAuth2 token");
                    return;
                }
                OAuthToken = token.AccessToken;
            });
            UserManager.OnCurrentUserUpdate += async () =>
            {
                User = UserManager.GetCurrentUser();
            };
            Connected = true;
            GD.Print("Created Discord Core");
        }
        catch (Exception exception)
        {
            GD.Print($"Failed to create Discord Core: {exception}");
            return;
        }

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
            Core!.RunCallbacks();
        }
        catch (ResultException exception)
        {
            resultError(exception);
        }
    }

    private void disable()
    {
        Connected = false;
        _callbackTimer.Dispose();
        Core?.Dispose();
    }
}
