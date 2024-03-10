namespace Rhythia.Online
{
    public interface IHasOnlineId<T>
    {
        T OnlineId { get; set; }
    }
}