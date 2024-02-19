namespace Rhythia.Core.Online.Spectator;

public interface ISpectatorClient
{
    Task StreamStarted(string userId, StreamInfo streamInfo);
    Task StreamEnded(string userId);
    Task StreamDataReceived(string userId, StreamData streamData);
}