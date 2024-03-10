namespace Rhythia.Settings
{
    public class SettingsContainer
    {
        public MetaSettings MetaSettings { get; set; } = new();
        public WindowSettings WindowSettings { get; set; } = new();
        public DebugSettings DebugSettings { get; set; } = new();

        public AuthSettings? AuthSettings; // Loaded from elsewhere
    }
}