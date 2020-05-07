# LSL-Projects
Collection of LSL scripts written by me.

## What is LSL?
LSL stands for Linden Scripting Language. It's a proprietary scripting language designed for Second Life, by Linden Lab.

LSL is a procedural, event-based language running on [Mono](https://www.mono-project.com/). Scripts are self-contained (up to 64KB memory) and can be restarted/compiled into bytecode during runtime. Bytecode is also shared between all identical scripts to reduce memory usage.

### Example
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
### Data Types
- All data types are pass-by-value.
- All data types are zero-initialized.
- integer
  - Signed 32-bit value (-2147483648, +2147483647)
  - Supports hexadecimal notation, eg. `0x80000000`
- float
  - 32-bit IEEE-754 floating point number
  - Supports scientific notation, eg. `3.402823466E+38`
  - `5.0`, `5`, and `.5` are all valid floats
- string
  - Strings are enclosed in double-quotes: `"Hello, world!"`
  - Can be concatenated with the `+` operator
  - Maximum length is only limited by available script memory
  - Any characters are valid, except NUL aka `llUnescapeURL("%00")` cannot exist
    - (The function returns a zero-length empty string: `""`)
- key
  - Also known as Universal Unique Identifier (UUID)
  - Consists of 32 hexadecimal characters and 4 fixed hyphens, eg: `"01234567-89ab-cdef-0123-456789abcdef"`
  - Most entities in Second Life have an UUID, including avatars, objects, groups, textures, sounds, animations, inventory items, etc.
- vector
  - Contains a set of 3 floats: X Y Z
  - Syntax: `<1.0, 2.0, 3.0>` or `<0, -1, 20.0>`
  - Operators:
    - `+` Addition
    - `-` Subtraction
    - `*` Multiplication, Dot-product
    - `%` Cross-product
  - Each component can be individually accessed through a variable
    - `vector vec = <1,1,1>; vec.x = 3;`
- rotation
  - Contains a set of 4 floats: X Y Z S (Quaternion)
  - Syntax: `<0, 0, 0, 1>`
  - All quaternions are normalized by default
  - Rotations can be combined/composed with `*`, eg: `rotation * rotation`
  - Vectors can be rotated with `*`, eg: `vector * rotation`
  - Negative rotation can be done with the `\` operator in both cases
  - Each component can be individually accessed through a variable
    - `rotation rot = <0,0,0,1>; rot.x = 0.70710676; rot.s = 0.70710676;`
- list
  - Contains zero or more elements of any other data type
  - Cannot contain lists
  - Cannot be multi-dimensional
  - Can be concatenated with the `+` operator
  - Syntax: `[]` or `["Hello, ", 3.14, "!"]`
    - Values must be retrieved through functions like `llList2String` or `llList2Float`, which will return the respective zero-value for invalid elements
    - `llList2Float(["I'm a string"], 0)` would return `0.0`
  - Equality test (`==`) only compares list lengths

### Environment details
Collectively, scripts are scheduled a timeslice during each server frame after everything else has been processed, such as avatar (agent/user) interactions and physics simulation. Because of this, not all scripts are guaranteed to run each frame. A single server can also host multiple "regions" so the "total frame time" is split between each region.

![For example](http://puu.sh/FGByP/b7d4377d1e.png)

Scripts may also travel from one region to another. During this process, the current memory and runtime of the script is suspended and transferred to the other region, where it will continue as normal and possibly receive new events alerting the script to the change in environment. This process is an almost invariably slow process for the receiving region, causing all simulation (and scripts) to slow down for a few seconds.

### Footnotes

The official Wiki: http://wiki.secondlife.com/wiki/LSL_Portal

The official website: https://secondlife.com/

I am not affiliated with Linden Lab.
