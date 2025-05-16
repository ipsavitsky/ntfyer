# ntfyer

> [!WARNING]
> This software is very underdeveloped, use at your own risk

This is a daemon designed to connect to an ntfy instance and listen for notifications and transform them to native notifications.

## Building

Install `libnotify` and `zig` v0.14.0 from your package manager.

To build, just run `zig build`. A nix package is also available.

## Configuring

By default, ntfyer looks for `config.zon` in the directory it was started in. Path to it can also be supplied via `-c <path>` flag.

Structure of `config.zon`:

```zig
.{
    .ntfy = .{
        .token = "<put token here>",
        .hostname = "ntfy.example.com",
    },
    .topics = .{ "topic1", "topic2" },
}
```
