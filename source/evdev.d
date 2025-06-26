import std.stdio : File;
import core.sys.posix.fcntl : fcntl,O_NONBLOCK,F_SETFL,F_GETFL;
import core.sys.posix.poll  : poll,pollfd,POLLIN,POLLHUP,POLLERR;
import exceptions;
import what;


struct 
Evdev {
    string _device;          // "/dev/input/event8"
    int    _timeout = 1000;  // ms
    File   _file;
    What   _what;
    bool   _ready;

    alias   front    = _what;
    alias   empty    = _check_file;
    alias   popFront = _read;


    this (string device) {
        this._device = device;
        _init ();
    }

    this (string device, int timeout) {
        this._device  = device;
        this._timeout = timeout;
        _init ();
    }

    void 
    _init () {
        _open ();
        _non_block ();
    }

    void
    _open () {
        _file.open (_device,"rb");
    }

    void
    _non_block () {
        int flags = fcntl (_file.fileno,F_GETFL,0);
        fcntl (_file.fileno,F_SETFL,flags|O_NONBLOCK);
    }

    void
    _read () {
        _file.rawRead ((&front.input)[0..1]);
    }

    auto
    _check_file () {
        return _poll ();
    }

    auto
    _poll () {
        auto fds = pollfd (_file.fileno,POLLIN);

        // poll
        auto _polled =
            poll (
                &fds,     // file descriptors
                1,        // number of file descriptors
                _timeout  // timeout ms
            );

        // check
        if (_check_polled (_polled,fds))
            return false; // OK
        else
        // timeout
        if (_polled == 0)
            return true;  // empty
        // error
        else {
            _on_polled_error (_polled,fds);
            return true;  // error
        }
    }

    bool
    _check_polled (P,FDS) (P _polled, FDS fds) {
        return (_polled > 0 && (fds.revents & POLLIN));
    }

    void
    _on_polled_error (P,FDS) (P _polled, FDS fds) {
        import core.stdc.errno : errno,EAGAIN,EINTR;
        import core.sys.posix.poll : poll,pollfd,POLLIN,POLLHUP,POLLERR;


        // timeout
        if (_polled == 0)
            throw new InputException ("poll timeout");
        else

        // error
        if (_polled < 0) {
            // soft error - no event
            switch (errno) {
                case EAGAIN: throw new InputException ("EAGAIN");
                case EINTR : throw new InputException ("EAGAIN");
                default    : throw new InputException ("EINVAL");
            }
        }
        else

        // HUP - device disconnected
        if (fds.revents & POLLHUP)
            throw new InputException ("POLLHUP");
        else

        // ERR - device error
        if (fds.revents & POLLERR)
            throw new InputException ("POLLERR");
    }
}
