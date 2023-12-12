using System.Threading.Tasks;
using Godot;

namespace Rhythia.Game;
public partial class Online : Node
{
	public static bool Connected { get; private set; } = false;
	public static string UserId { get; private set; } = "test123 abababab";
}
