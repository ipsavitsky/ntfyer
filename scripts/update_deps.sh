#!/usr/bin/env bash

zig fetch --save git+https://github.com/Cloudef/zig-aio.git#zig-0.14
zon2nix --nix=nix/build.zig.zon.nix build.zig.zon
