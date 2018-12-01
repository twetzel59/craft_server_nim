# A new server for Craft

This is a WIP multiplayer server for [Craft](https://github.com/fogleman/Craft). It is written in
[Nim](https://nim-lang.org), a rising fast and elegant compiled language with a clean syntax.
Check it out!

After writing a [mostly complete Craft server](https://github.com/twetzel59/craft_server)
in [Rust, a fairly new super-performant systems language](https://rust-lang.org),
I decided to try the same in Nim. I expect both languages to produce performant code for the
server implementation. In fact, the Nim version might be faster, as I'll be using Nim's built-in
support for async IO.

Keep in mind this is developed on (nearly) the latest git of the Nim toolchain.
Please compile using the `devel` branch of https://github.com/nim-lang/Nim.
