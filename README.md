# AsmSys

A lightweight x86-64 Linux system information tool written entirely in NASM Assembly. No C runtime, just pure syscalls.

## Status

AsmSys is in early development. It currently reads real system information directly from the Linux kernel using x86-64 system calls.

## Current Features

- [x] Hostname
- [x] Kernel version
- [x] Architecture
- [x] System uptime
- [x] CPU information
- [x] Memory information
- [x] Disk information
- [x] Command-line flags
- [x] Cleaner terminal formatting

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

## Example Output

```text
AsmSys
Hostname     : my-linux-pc
Kernel       : 6.x.x
Architecture : x86_64
CPU          : Example x86-64 Processor
Memory       : 2048 MiB / 8192 MiB
Disk /       : 42 GiB / 120 GiB
Uptime       : 2d 4h 17m
```

Values are read from the machine running AsmSys.

## Project Structure

```text
AsmSys/
├── src/
│   └── main.asm
├── Makefile
├── .gitignore
└── README.md
```

## How It Works

AsmSys does not use libc. The program starts at `_start` and communicates with Linux directly through x86-64 system calls.

The current implementation uses `uname` for hostname, kernel and architecture information, reads the CPU model from `/proc/cpuinfo`, and uses `sysinfo` for memory and uptime.

## License

A license will be added before the first stable release.


## Command-line Options

```text
./asmsys --cpu
./asmsys --memory
./asmsys --disk
./asmsys --all
./asmsys --help
./asmsys --version
```

Running `./asmsys` without an option displays the full system summary.


## Development

Every push and pull request to `main` is built automatically with GitHub Actions. The workflow assembles and links AsmSys, then runs basic command-line smoke tests.

Current development version: `v0.1.0`
