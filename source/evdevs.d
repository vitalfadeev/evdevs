import evdev;

import std.range           : front,back,zip;
import core.sys.posix.poll : poll,pollfd,POLLIN,POLLHUP,POLLERR;
import exceptions;
import what;


struct
Evdevs {
    Evdev[]  _devs;  // name,fd,what
    What     _what;
    int      _timeout = 1000;

    alias   front    = _what;
    alias   empty    = _check_files;
    alias   popFront = _read;

    this (string[] paths) {
        foreach (ref p; paths)
            _add_device (p);
    }

    void
    _add_device (string path) {
        _devs ~= Evdev (path);
    }

    void
    _read () {
        // which first ?
        //   time !
        //
        // find min time
        Timeval min_time = Timeval (time_t.max,suseconds_t.max);
        Evdev*  min_dev;
        foreach (ref _dev; _devs)
            if (_dev._ready)
            if (_dev.front.input.time < min_time) {
                min_time =  _dev.front.input.time;
                min_dev  = &_dev;
            }

        _what.input    = min_dev._what.input;
        _what.device   = min_dev;
        min_dev._ready = false;
    }

    auto
    _check_files () {
        return _poll ();
    }

    auto
    _poll () {
        size_t _ready;

        // skip ready
        pollfd[] _fds;
        _fds.reserve (_devs.length);
        
        Evdev*[] _fds_devs;
        _fds_devs.reserve (_devs.length);

        foreach (ref _dev; _devs)
            if (_dev._ready) {
                _ready ++;
            }
            else {
                _fds      ~= pollfd (_dev._file.fileno,POLLIN);
                _fds_devs ~= &_dev;
            }

        // check devices or wait
        auto _timeout = 
            (_ready) ? 
                0 :
                this._timeout;

        // poll
        auto _polled =
            poll (
                _fds.ptr,     // file descriptors
                _fds.length,  // number of file descriptors
                _timeout      // timeout ms
            );

        // check
        if (_check_polled (_polled,_fds,_fds_devs,_ready))
            return false; // OK
        else
        // timeout
        if (_polled == 0)
            return true;  // empty
        // error
        else {
            _on_polled_error (_polled,_fds);
            return true;  // error
        }
    }

    size_t
    _check_polled (P,FDS,DEVS,READY) (P _polled, FDS _fds, DEVS _fds_devs, READY _ready) {
        if (_polled > 0) {
            foreach (ref _fd,_dev; zip (_fds,_fds_devs))
                if (_fd.revents & POLLIN) {
                    _dev._read ();
                    _dev._ready = true;
                    _ready ++;
                }
        }

        return _ready;
    }

    void
    _on_polled_error (P,FDS) (P _polled, FDS _fds) {
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

        {
            foreach (ref fd; _fds) {
                // HUP - device disconnected
                if (fd.revents & POLLHUP)
                    throw new InputException ("POLLHUP");
                else

                // ERR - device error
                if (fd.revents & POLLERR)
                    throw new InputException ("POLLERR");
            }
        }
    }
}

