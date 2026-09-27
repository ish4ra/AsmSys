# AsmSys

A lightweight x86-64 Linux system information tool written entirely in NASM Assembly. No C runtime, just pure syscalls.

## Status

AsmSys is in early development. The current version provides the initial NASM x86-64 program structure and build system.

## Requirements

- Linux x86-64
- NASM
- GNU `ld`
- GNU Make

## Build

```bash
git clone https://github.com/ish4ra/AsmSys.git
cd AsmSys
make
```

Run it with:

```bash
./asmsys
```

Or:

```bash
make run
```

## Current Output

AsmSys currently identifies its target architecture, runtime approach, and implementation language.

## Roadmap

- [ ] Hostname
- [ ] OS and kernel information
- [ ] CPU information
- [ ] Memory information
- [ ] System uptime
- [ ] Disk information
- [ ] Command-line flags
- [ ] Cleaner terminal formatting

## Project Structure

```text
AsmSys/
├── src/
│   └── main.asm
├── Makefile
├── .gitignore
└── README.md
```

## License

A license will be added before the first stable release.
