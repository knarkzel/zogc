# zick

Game engine for the Wii in Zig. Dependencies: [zig](https://ziglang.org/),
[dolphin-emu](https://dolphin-emu.org/), [devkitPro](https://devkitpro.org/wiki/Getting_Started).

```bash
git clone https://github.com/knarkzel/zick
cd zick/
zig build
```

- To build and run with Dolphin, do `zig build run`
- To build and deploy to Wii over network (must be in Homebrew menu), do `zig build deploy`

# Get Wii IP

Make sure you're on the same network. Then run following, and look for `(Nintendo)`:

```bash
$ ip addr | grep "inet 10\|192" | awk '{print $2}' | xargs sudo nmap -sn
Starting Nmap 7.92 ( https://nmap.org ) at 2022-05-25 22:21 CEST
Nmap scan report for 192.168.11.171
Host is up (0.018s latency).
MAC Address: AA:BB:CC:DD:EE:FF (Nintendo)
```

Take this IP and change the `ip` variable inside `build.zig`.
