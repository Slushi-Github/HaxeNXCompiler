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