# How to create a library for this tool

Creating a Haxe library is no different from creating a normal Haxe library, but there are some important additions. 

When you create a new library, you can use a special JSON file to give HaxeNXCompiler more information about what to do with your library, especially when compiling.

The file is called  ``HxNX_Meta.json`` and it is located in the root of the library.

This file has the following structure:

```json
{
    "libVersion": "0.0.0",
    "haxeLibs": [],
    "switchLibs": [],
    "mainDefines": [],
    "hxDefines": [],
    "cDefines": [],
    "cppDefines": []
}
```

``libVersion`` is the version of the library, it is used to check if the library is the required version.

``haxeLibs`` is an array of Haxe library names that this library depends on.

``switchLibs`` is an array of Switch homebrew library names that this library depends on.

``mainDefines`` is an array of defines that will be added to the main project, for Haxe and C/C++.

``hxDefines`` is an array of defines that will be added to the main project, for Haxe only.

``cDefines`` is an array of defines that will be added to the main project, for C only.

``cppDefines`` is an array of defines that will be added to the main project, for C++ only.

If HaxeNXCompiler cannot find the file, it will only import the library as a normal Haxe library.

---------

- [About assets](./AssetsGuide.md)