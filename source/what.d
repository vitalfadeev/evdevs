import std.format : format;


struct
What {
    Input_Event input;
    void*       window;
    void*       user;
    void*       device;

    string
    toString () {
        return format!"What (%s)" (input);
    }
}

struct
Input_Event {
    Timeval time;  // long, long
    Type    type;  // EV_KEY, EV_REL, EV_ABS, EV_MSC, EV_SW, EV_LED, EV_SND, EV_REP, EV_FF, EV_PWR, EV_FF_STATUS
    ushort  code;
    uint    value;

    string
    toString () {
        return format!"Input_Event (%s)" (type);
    }
}

// evdev
//   include/uapi/linux/input-la-codes.h
//     EV_SYN, EV_KEY, EV_REL, EV_ABS, EV_MSC, EV_SW, EV_LED, EV_SND, EV_REP, EV_FF, EV_PWR, EV_FF_STATUS
import input_event_codes;
enum 
Type : ushort {
    syn       = EV_SYN,
    key       = EV_KEY,
    rel       = EV_REL,
    abs       = EV_ABS,
    msc       = EV_MSC,
    sw        = EV_SW,
    led       = EV_LED,
    snd       = EV_SND,
    rep       = EV_REP,
    ff        = EV_FF,
    pwr       = EV_PWR,
    ff_status = EV_FF_STATUS,
    max       = EV_MAX,
    // custom
    draw      = EV_MAX + 1,
}

struct 
Timeval {
    time_t      tv_sec;
    suseconds_t tv_usec;

    auto
    opCmp (Timeval b) {
        if (tv_sec < b.tv_sec)
            return -1;
        else
        if ((tv_sec == b.tv_sec) && (tv_usec < b.tv_usec))
            return -1;
        else
        if (tv_sec > b.tv_sec)
            return 1;
        else
        if ((tv_sec == b.tv_sec) && (tv_usec > b.tv_usec))
            return 1;
        else
        if ((tv_sec == b.tv_sec) && (tv_usec == b.tv_usec))
            return 0;
        
        return 0;
    }
}

alias time_t      = ulong;  // c_long = 'ulong' on 64-bit systen
alias suseconds_t = ulong;

unittest  {
    auto a = Timeval (0,0);
    auto b = Timeval (0,1);
    assert (a<b);
    assert (!(a>b));
    assert (!(a==b));

    a = Timeval (0,0);
    b = Timeval (1,0);
    assert (a<b);
    assert (!(a>b));
    assert (!(a==b));

    a = Timeval (0,1);
    b = Timeval (0,1);
    assert (!(a<b));
    assert (!(a>b));
    assert (a==b);
    
    a = Timeval (0,1);
    b = Timeval (0,0);
    assert (!(a<b));
    assert (a>b);
    assert (!(a==b));
    
    a = Timeval (1,0);
    b = Timeval (0,0);
    assert (!(a<b));
    assert (a>b);
    assert (!(a==b));
}
