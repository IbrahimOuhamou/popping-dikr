// بسم الله الرحمن الرحيم
// la ilaha illa Allah Mohammed Rassoul Allah

const std = @import("std");
const c = @import("c.zig").c;

pub const Config = @This();

pub const WindowType = enum {
    fixed_width,
    follow_height,
};

// const config_zon =
//     \\.{
//     \\  .screen_h: u16 = 100,
//     \\  .screen_w: u16 = 400,
//     \\
//     \\  .bg_color = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
//     \\  .text_color = .{ .r = 0, .g = 0, .b = 0, .a = 255 },
//     \\
//     \\  .sleep_time_minutes = 16,
//     \\  .display_time_seconds = 5,
//     \\}
// ;

window_type: WindowType = .fixed_width,

window_h: u16 = 100,
window_w: u16 = 400,

bg_color: c.SDL_Color = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
text_color: c.SDL_Color = .{ .r = 0, .g = 0, .b = 0, .a = 255 },

sleep_time_minutes: u16 = 16,
display_time_seconds: u16 = 5,

font_path: ?[:0]const u8 = null,

pub fn loadConfig(allocator: std.mem.Allocator) Config {
    const app_data_dir_path = get_data_dir: {
        if (std.fs.getAppDataDir(allocator, "popping-dikr")) |add| break :get_data_dir add else |err| {
            std.log.err("Error opening App data dir: '{any}'\n", .{err});
        }

        return Config{};
    };
    defer allocator.free(app_data_dir_path);

    blk: {
        const app_data_dir = std.fs.openDirAbsolute(app_data_dir_path, .{}) catch |err| {
            std.log.err("Error opening App data dir: '{any}'\n", .{err});
            break :blk;
        };

        const settings_file = app_data_dir.openFile("settings.zon", .{}) catch |err| {
            std.log.err("Error opening settings file in '{s}': '{any}'\n", .{ app_data_dir_path, err });
            break :blk;
        };

        const stat = settings_file.stat() catch |err| stat: {
            std.log.err("Error getting settings file stats '{s}': '{any}'", .{ app_data_dir_path, err });
            break :stat null;
        };

        const settings_file_content = settings_file.readToEndAllocOptions(allocator, 1024 * 1024, if (stat) |_| stat.?.size else null, @alignOf(u8), 0) catch |err| {
            std.log.err("Error reading settings file in '{s}': '{any}'\n", .{ app_data_dir_path, err });
            break :blk;
        };
        defer allocator.free(settings_file_content);

        var zon_parse_status: std.zon.parse.Status = .{};
        return std.zon.parse.fromSlice(Config, allocator, settings_file_content, &zon_parse_status, .{ .ignore_unknown_fields = true }) catch |err| switch (err) {
            else => {
                std.log.err("Error reading settings file in '{s}': '{any}'", .{ app_data_dir_path, err });
                var err_it = zon_parse_status.iterateErrors();
                while (err_it.next()) |zon_err| {
                    std.log.err("{s}\n{any}", .{zon_err.fmtMessage(&zon_parse_status), zon_err.getLocation(&zon_parse_status)});
                }
                break :blk;
            },
        };
    }

    return Config{};
}

