namespace Rhythia.Settings
{
    public class DebugSettings
    {
        public NoteRenderMode NoteRenderMode { get; set; } = NoteRenderMode.Mesh;
        public NoteSpawnMode NoteSpawnMode { get; set; } = NoteSpawnMode.Automatic;
        public double BreakTime { get; set; } = 5.0; // Minimum break time
        public double SkipTime { get; set; } = 2.0; // Minimum skip time
    }

    public enum NoteRenderMode
    {
        Mesh, // Every note has a mesh
        MultiMesh // Notes are rendered by a MultiMesh
    }

    public enum NoteSpawnMode
    {
        Preload, // Spawns everything at the start of the map
        OnDemand, // Spawns things as they are needed
        Automatic // Decides from the previous two based on the map
    }
}