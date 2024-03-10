namespace Rhythia.Game.Settings;

public class WindowSettings
{
    public FramerateMode FramerateMode { get; set; } = FramerateMode.VSync;
    public int CustomFramerate { get; set; } = 60;
    public WindowMode WindowMode { get; set; } = WindowMode.WindowedMaximised;
}
public enum FramerateMode
{
    VSync,
    Unlimited,
    Custom
}

public enum WindowMode
{
    Windowed,
    WindowedMaximised,
    WindowedFullscreen,
    Fullscreen
}