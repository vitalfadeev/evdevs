import std.stdio;
import std.format : format;
import std.conv : to;
import evdev;
import evdevs;

void 
main () {
    //{
    //    auto evdev = Evdev ("/dev/input/event8");

    //    while (true) {
    //        foreach (ref what; evdev)
    //            writeln (what);

    //        import core.sys.posix.unistd : sleep;
    //        sleep (1);
    //    }
    //}
    {
        // cat /proc/bus/input/devices

        auto evdevs = 
            Evdevs ([
                "/dev/input/event8",  // mouse
                "/dev/input/event0",  // keyboard
                "/dev/input/event11", // keyboard (USB)
            ]);

        while (true) {
            foreach (ref what; evdevs)
                writeln (what);  
                // syn,key,syn - mouse btn down
                // syn,key,syn - mouse btn up
        }
    }
}

