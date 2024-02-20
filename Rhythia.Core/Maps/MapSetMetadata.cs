namespace Rhythia.Core.Maps;

[Serializable]
public class MapSetMetadata
{
    public string Id { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Artist { get; set; } = string.Empty;
    public string Source { get; set; } = string.Empty;
    public string AudioPath { get; set; } = string.Empty;
    public List<string> Tags { get; set; } = new();

}