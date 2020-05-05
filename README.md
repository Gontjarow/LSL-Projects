# LSL-Projects
Collection of LSL scripts written by me.

## What is LSL?
LSL stands for Linden Scripting Language. It's a proprietary scripting language designed for Second Life, by Linden Lab.

LSL is a procedural, event-based language running on [Mono](https://www.mono-project.com/). Scripts are self-contained (up to 64KB memory) and can be restarted/compiled into bytecode during runtime. Bytecode is also shared between all identical scripts to reduce memory usage.

The syntax is simple and similar to the C-family. It doesn't have classes but it does have dynamic lists that can contain mixed types. Here is the default script that is created every time you add a new script to an object:
```
default // State
{
    state_entry() // Event
    {
        llSay(0, "Hello, Avatar!");
    }

    touch_start(integer total_number)
    {
        llSay(0, "Touched.");
    }
}
```

Collectively, scripts are scheduled a timeslice during each server frame after everything else has been processed, such as avatar (agent/user) interactions and physics simulation. Because of this, not all scripts are guaranteed to run each frame. A single server can also host multiple "regions" so the "total frame time" is split between each region.

![For example](http://puu.sh/FGByP/b7d4377d1e.png)

The official Wiki: http://wiki.secondlife.com/wiki/LSL_Portal
The official website: https://secondlife.com/

I am not affiliated with Linden Lab.
