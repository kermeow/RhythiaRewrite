namespace Rhythia.Core.Online;

public interface IHasOnlineId<T>
{
    T OnlineId { get; set; }
}