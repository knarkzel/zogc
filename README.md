# zogc

Game engine for the Wii in Zig with zero-fuss installation.

```bash
git clone https://github.com/knarkzel/zogc
cd zogc/
zig build
```

## Commands

- To build and run with Dolphin, do `zig build run`
- To build and deploy to Wii over network (must be in Homebrew menu), do `zig build deploy`
- To build and debug crash addresses, do `zig build line -- <addresses>`
