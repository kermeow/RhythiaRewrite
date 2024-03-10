using System;
using System.Text.Json.Serialization;

namespace Rhythia.Maps
{
    [Serializable]
    public class MapMetadata
    {
        public string Title { get; set; } = string.Empty;
        public string Artist { get; set; } = string.Empty;
        public string FriendlyName => Artist.Length > 0 ? $"{Artist} - {Title}" : Title;
        public string AudioPath { get; set; } = string.Empty;
        public string CoverPath { get; set; } = string.Empty;
    }
}