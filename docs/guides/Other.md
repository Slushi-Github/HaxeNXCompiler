## NXLink

For use the nxlink server, first you need to compile your project with the define ``ENABLE_NXLINK`` as C define:

```xml
<cdef name="ENABLE_NXLINK"/>
```

then you can use the ``--send --server`` (or ``-s -s``) command to send the ``.nro`` file to the Nintendo Switch with the server started.

Now you need to start the nxlink client on your program:

```haxe
// import the nxlink class from hx_libnx
import switchLib.runtime.Nxlink;

// Initialize nxlink
if (Nxlink.nxlinkStdio() < 0) {
    Sys.println("Failed to redirect logs to NXLink! Maybe it's not running or not required?");
}
```

And that's it! your logs now will be sent to the nxlink server and you can see them on the terminal.

## Using Haxe Debugger

To use the well-known `hxcpp-debug-server` library, you need to do two things:

1. On your console, go to this file (if it doesn't exist, create it): `sd:/atmosphere/config/system_settings.ini`, where you will put the following:

```ini
[atmosphere]
enable_htc = u8!0x0
enable_standalone_gdbstub = u8!0x1
```

After doing that, restart your console.

This first step is required; otherwise, **the program will crash as soon as it opens and tries to connect to the debugger**.

2. You need this fork of the VS Code extension: [hxcpp-debugger-remoting](https://github.com/Slushi-Github/hxcpp-debugger-remoting). Instructions on how to use it are explained right there.
