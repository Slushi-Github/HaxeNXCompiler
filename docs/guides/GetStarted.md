# Getting Started

### Small recommendation:
It is advisable to test on real hardware. I do not recommend using emulators, not only because they sometimes fail to show certain errors that occur on a real console, but also because they can crash for no reason, whereas a real console does not. If you are going to use an emulator, I recommend Yuzu, as it gives the best results, but the emulator will crash if there are errors. so really, use a real console. The Nintendo Switch is quick to restart if the crash occurred in applet mode. If you do it from a game that has already started, only Nintendo's crash handler should appear. 

---------

(Fun fact: if you're on ARM64, like the Nintendo Switch running Linux, you can use this tool!)

Let's start with what may be the most tedious, but not necessarily difficult, part, and that is DevKitPro, the development environment for Wii, Gamecube, DS, 3DS, Wii U, and Switch. In this case, we are only interested in Switch.

Fortunately, they have their own guide. In any case, if you follow it correctly, you will have the basic dependencies for Nintendo Switch: [*link to guide*](https://devkitpro.org/wiki/Getting_Started)

---------

You also need Haxe, get it [here](https://haxe.org).

---------

Now, the only thing left is to download HaxeNXCompiler:

* From releases: *[Last release](https://github.com/Slushi-Github/HaxeNXCompiler/releases/latest)*

* From GitHub Actions (recomended option): *Go to [Actions](https://github.com/Slushi-Github/HaxeNXCompiler/actions)*

* Your own compilation: [*How to compilate HaxeNXCompiler*](./compile.md)

---------

Create a new folder for your project, copy the ``HaxeNXCompiler`` executable that you downloaded (or compiled) to this new folder.

Open a terminal and start with your first command:

```bash
haxelib newrepo
```

Why create a new local Haxelib repository? Because we are going to use modified libraries from the standard Haxe libraries, it is more convenient and safer for them to be in their own place without interfering with other projects you may have that depend on the same library, It is not mandatory, but it is what I recommend.

---------

Now you need two libraries that are mandatory for a project using this tool:

```bash
# Get the modified version of hxcpp-nx, the hxcpp for the Nintendo Switch
haxelib git hxcpp https://github.com/Slushi-Github/hxcpp-nx
```

```bash
# Get the libnx bindings for Haxe, The homebrew SDK for the Nintendo Switch
haxelib git hx_libnx https://github.com/Slushi-Github/hx_libnx
```

---------

Now you are ready to get started with HaxeNXCompiler!

Create your main class inside a folder of your choice for your source code. 

**Example:**

``source/Main.hx``:

```haxe
package source;

import cpp.Pointer;

import switchLib.services.Applet;
import switchLib.services.Hid.HidNpadButton;
import switchLib.services.Hid.HidNpadStyleTag;
import switchLib.runtime.devices.Console;
import switchLib.runtime.Pad;
import switchLib.Result;
import switchLib.Types.ResultType;

/**
 * Basic example of printing "Hello, World!" to the screen of the Nintendo Switch
 */
class Main 
{
    public static function main() 
    {
        // Initialize the console for printing to the screen
		Console.consoleInit(null);

        // Print "Hello, World!" using Haxe functions (I believe that ``trace("")`` does not work for this)
        Sys.println("Hello, World!");

        // Set up the pad, this is the controller
		Pad.padConfigureInput(1, HidNpadStyleTag.HidNpadStyleSet_NpadStandard);
		var pad:PadState = new PadState();
		Pad.padInitializeDefault(Pointer.addressOf(pad));

        // main loop
		while (Applet.appletMainLoop()) {

            // Update the pad
			Pad.padUpdate(Pointer.addressOf(pad));

            // Check if the plus button on the controller is pressed
			var kDown:Int = Pad.padGetButtonsDown(Pointer.addressOf(pad)).toInt();
			if (kDown & HidNpadButton.HidNpadButton_Plus != 0) {
                // If it is pressed, break the loop
				break;
			}

            // Update the screen constantly
			Console.consoleUpdate(null);
		}

        // Close the console
		Console.consoleExit(null);
    }
}
```

---------

You have your code ready, right? Well, now use this command to create your project file:

```bash
HaxeNXCompiler --prepare
```

**Configure it to your needs. By default, the ``--prepare`` command will only generate a sample XML file.**

---------

Now you can use this command to compile your project:

```bash
HaxeNXCompiler --compile
```

---------

Once ready, you will have your executables ready for Nintendo Switch in ``yourOutputFolder/switchFiles``!

---------

More help information:

- [About assets](./AssetsGuide.md)
- [About libraries](./LibrariesGuide.md)
- [Program Commands](/assets/CommandsInfo) (This is directly from the file used by the already compiled tool.)