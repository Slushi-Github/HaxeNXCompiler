<h1 align="center">HaxeNXCompiler</h1>
<h2 align="center">A tool for creating homebrew for the Nintendo Switch using Haxe</h2>

![mainImage](https://github.com/Slushi-Github/HaxeNXCompiler/blob/main/docs/readme/MainImage.png)

Using this utility (Inspired by [HxCompileU](https://github.com/Slushi-Github/hxCompileU)) you can compile code from Haxe to the Nintendo Switch using [DevKitPro](https://devkitpro.org) and [custom hxcpp fork](https://github.com/Slushi-Github/hxcpp-nx), for creating homebrew for the Nintendo Switch using Haxe.

This is inspired by an attempt by the [RetroNX Team](https://github.com/retronx-team) to use Haxe on the Nintendo Switch. I used part of the [original project](https://github.com/retronx-team/switch-haxe) for this, so credit goes to them for achieving this in the first place!

**This project is being tested with Haxe 4.3.7 and a Nintendo Switch V2 with firmware 20.4.0 (AMS 1.9.4).**

Officially there are supported libraries to be used in conjunction with HaxeNXCompiler:

- [hx_libnx](https://github.com/Slushi-Github/hx_libnx): Haxe/hxcpp @:native bindings for libnx, the Nintendo Switch's homebrew library.

-----

## How?

Well... Unlike the Wii U, where using hxcpp causes many problems, and to achieve that I had to use [Reflaxe/C++ (Amazing library!)](https://github.com/SomeRanDev/reflaxe.CPP) to be able to use Haxe on that console. With the Nintendo Switch, hxcpp compiles perfectly!

I knew even before I had a Wii U that the [RetroNX Team](https://github.com/retronx-team) had attempted to [use Haxe on the Nintendo Switch](https://github.com/retronx-team/switch-haxe), but that project is now more than five years old and I don't know if it still works. This program rescues what they did and does so using something more recent with respect to Haxe and hxcpp, and it uses inspiration from [HxCompileU](https://github.com/Slushi-Github/hxCompileU) to be able to easily compile Haxe code for the Nintendo Switch, in this case without the limitations that [HxCompileU](https://github.com/Slushi-Github/hxCompileU) may have because it uses [Reflaxe/C++ (And I'm not saying it's a bad library!)](https://github.com/SomeRanDev/reflaxe.CPP).

This does not work the same as [HxCompileU](https://github.com/Slushi-Github/hxCompileU). Haxe and hxcpp handle all possible compilation, and then only the link and creation of the program made for use on the Nintendo Switch are done.

This program what it does, is that by means of some data stored in a JSON file (``haxeNXConfig.json``), it generates a MakeFile and a [HXML](https://haxe.org/manual/compiler-usage-hxml.html) file with those data of the JSON, of normal first it will try to execute the [HXML](https://haxe.org/manual/compiler-usage-hxml.html) with Haxe, [hxcpp](https://github.com/Slushi-Github/hxcpp-nx) is in charge of compiling the C++ code, if the compilation with Haxe is successful, it executes the MakeFile with Make and starts the link of that C++ code to the Nintendo Switch, if this is also successful, that's it, you have your homebrew for the Nintendo Switch made with Haxe!

## Why?

Well, I've been having fun using the Nintendo Wii U with Haxe through my [HxCompileU](https://github.com/Slushi-Github/hxCompileU) project, and I was able to get a Nintendo Switch. I already knew that Haxe could work there without as many problems as on the Wii U, and it's even officially supported, but obviously under the terms of the Nintendo Developer Portal. This project aims to do the same thing without being part of that Nintendo program and to do everything through the homebrew that exists for the Nintendo Switch.

-----

# Usage

The basic usage of HaxeNXCompiler is as follows:

You need:
- [DevKitPro](https://devkitpro.org/wiki/Getting_Started)

- ``libnx`` (Install the ``libnx`` library from DevKitPro repository)

- [Haxe](https://haxe.org/)

- [hxcpp (fork)](https://github.com/Slushi-Github/hxcpp-nx)

- [hx_libnx](https://github.com/Slushi-Github/hx_libnx)

First, you need compilate this project, or you can use the precompiled version that is in the [releases](https://github.com/Slushi-Github/HaxeNXCompiler/releases), or you can download it from the [GitHub Actions](https://github.com/Slushi-Github/HaxeNXCompiler/actions). I recommend using the [GitHub Actions](https://github.com/Slushi-Github/HaxeNXCompiler/actions) option.

```bash
# Just clone the repository
git clone https://github.com/Slushi-Github/HaxeNXCompiler.git

# Install hxcpp
haxelib git hxcpp https://github.com/Slushi-Github/hxcpp-nx.git

# Install hx_libnx
haxelib git hx_libnx https://github.com/Slushi-Github/hx_libnx.git

# Compile the project
cd HaxeNXCompiler
haxe build.hxml
```

After that, you will get your executable ``HaxeNXCompiler`` in the "export" folder, for the moment, copy it to the root of the project folder you need it.

-----

## How to use

#### First, initialize your project, that is, create the configuration JSON file that HaxeNXCompiler will use, you can create it using this command:
``{haxeNXCompilerProgram} --prepare`` or ``{haxeNXCompilerProgram} --p``

 - Or you can import an existing JSON file from a Haxe library with the following command:
``{haxeNXCompilerProgram} --import HAXE_LIB`` or ``{haxeNXCompilerProgram} --i HAXE_LIB``

-----

#### Once you have configured your JSON file to what your project needs, you can use the following command to compile it:
``{haxeNXCompilerProgram} --compile`` or ``{haxeNXCompilerProgram} --c``

 - If you want enable the Haxe debug mode, you can use the following command:

    ``{haxeNXCompilerProgram} --compile --debug``

-----

#### You can also use the following command search a line of code in the ``.elf`` file from a line address of some log using devkitA64's ``aarch64-none-elf-addr2line`` program:

``{haxeNXCompilerProgram} --searchProblem [lineAddress]`` or ``{haxeNXCompilerProgram} --sp [lineAddress]``

-----

#### You can also use the following command send the ``.nro`` file to the Nintendo Switch using DevKitPro's ``nxlink`` program:

``{haxeNXCompilerProgram} --send`` or ``{haxeNXCompilerProgram} --s``

 - If you want start a server, you can use the following command:

    ``{haxeNXCompilerProgram} --send --server`` or ``{haxeNXCompilerProgram} --s --s``

-----

and that's it! if your compilation was successful on both Haxe and Nintendo Switch side, your ``.nro``, ``.ncap`` and ``.elf`` files will be in ``yourOutputFolder/switchFiles``.


## libraries JSON file

When you create a library that will be compatible with HaxeNXCompiler and you need it to import important things such as more Haxe libraries, or libraries and parameters for the MakeFile, add a file called ``HxNX_Meta.json`` to your library, which should have the following structure: 

(This is just an example; comments do not work in JSON (at least not in ``haxe.Json``))

```json
{
    "libVersion": "0.0.0", // Library version
    "haxeLibs": [], // more Haxe libraries
    "switchLibs": [], // C/C++ Libraries for the Nintendo Switch (from DevKitPro)
    "mainDefines": [], // Defines for Haxe and C/C++
    "hxDefines": [], // Haxe defines
    "cDefines": [], // C defines
    "cppDefines": [] // C++ defines
}
```

If HaxeNXCompiler cannot find a library with that file, it will import it only for Haxe.

## About aseets

### About RomFS

The ``romfs`` folder is a folder that contains files that will be added to the ``.nro`` file.

To use this, create a folder in the main folder directory (Who is ``yourOutputFolder``), or a library compatible with HaxeNXCompiler, called "assets" Inside that folder, there should be another folder called "ROMFS" From there, you can copy everything you want, and a folder named "romfs" into a other folder called "SWITCH_ASSETS" will be copied to ``yourOutputFolder``. The MakeFile will then copy those files to the ``.nro`` file, which can be accessed by searching the path "romfs:/" (you must first mount that path with [hx_libnx](https://github.com/Slushi-Github/hx_libnx)!).

### About the metadata for the ``.nro`` file

Inside the JSON file ``haxeNXConfig.json`` you will find the parameters ``appTitle``, ``appVersion``, and ``appAuthor``. You can fill in these fields with whatever information you want to be displayed in the Homebrew menu. 

In addition, if there is a file named "icon.jpg" or one named "YOUR_PROJECT_NAME.jpg" in your project's assets folder or in a folder, they will be copied to the "SWITCH_ASSETS" folder so that the ``.nro`` file can use them. If that ".jpg" file is not found in any library or in the main project, HaxeNXCompiler will automatically provide one in the "SWITCH_ASSETS" folder.

## License
This project is released under the [MIT license](https://github.com/Slushi-Github/HaxeNXCompiler/blob/main/LICENSE.md).