# A zig tale of TUI and DB

Another zig experiment

## Motivation

I want to experiment with zig, simple user interfaces and cool PostgreSQL 
features.

## Tech stack

- Zig 0.17.0
- PostgreSQL 18
- Podman 5.8.7

The following zig libraries are also present:

- zigzag
- pg.zig

## Initial setup

```bash
mrdir sample-zig-tui
cd sample-zig-tui
zig init
mkdir -p src/infra
touch src/infra/database.yml
# as the time of this writing, i did a fork to fix a simple build issue
zig fetch --save git+https://github.com/sombriks/zigzag#main
zig fetch --save git+https://github.com/karlseguin/pg.zig#master
```

## How to build

## How to test

## How to run

## Noteworthy
