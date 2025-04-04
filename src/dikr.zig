// بسم الله الرحمن الرحيم
// la ilaha illa Allah Mohammed Rassoul Allah

const std = @import("std");
const c = @cImport({
    @cDefine("SDL_DISABLE_OLD_NAMES", {});
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3/SDL_revision.h");
    // For programs that provide their own entry points instead of relying on SDL's main function
    // macro magic, 'SDL_MAIN_HANDLED' should be defined before including 'SDL_main.h'.
    @cDefine("SDL_MAIN_HANDLED", {});
    @cInclude("SDL3/SDL_main.h");
    @cInclude("SDL3_ttf/SDL_ttf.h");
});

const font_data = @embedFile("KacstPoster.ttf");

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
const adkar = [_][:0]u8{
    @constCast("\u{FEEA}\u{FEE0}\u{FEDF}\u{FE8D} \u{FEE2}\u{FEB4}\u{FE91}"),
    @constCast("\u{FEEA}\u{FEE0}\u{FEDF}\u{FE8D} \u{FEE6}\u{FEA4}\u{FE92}\u{FEB3}"),
    @constCast("\u{FEAA}\u{FEE4}\u{FEA4}\u{FEE3} \u{FEF0}\u{FEE0}\u{FECB} \u{FEEA}\u{FEE0}\u{FEDF}\u{FE8D} \u{FEF0}\u{FEE0}\u{FEBB}"),
    @constCast("\u{FEEA}\u{FEE0}\u{FEDF}\u{FE8D} \u{FEAE}\u{FED4}\u{FED0}\u{FE98}\u{FEB3}أ"),
    @constCast("\u{FEEA}\u{FEE0}\u{FEDF}\u{FE8D} ﻻإ \u{FEEA}\u{FEDF}إ ﻻ"),
    @constCast("\u{FEAE}\u{FE92}\u{FEDB}أ }\u{FEEA}\u{FEE0}\u{FEDF}\u{FE8D}"),
};

const WindowType = enum {
    fixed_width,
    follow_height,
};

const Config = struct {
    window_type: WindowType = .fixed_width,

    window_h: u16 = 100,
    window_w: u16 = 400,

    bg_color: c.SDL_Color = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
    text_color: c.SDL_Color = .{ .r = 0, .g = 0, .b = 0, .a = 255 },

    sleep_time_minutes: u16 = 16,
    display_time_seconds: u16 = 5,

    font_path: ?[:0]const u8 = null,
};

var config: Config = Config{};

pub fn main() !void {
    var bismi_allah: []u8 = undefined;
    bismi_allah = adkar[2];

    // config = try std.zon.parse.fromSlice(Config, std.heap.c_allocator, config_zon, null, .{ .ignore_unknown_fields = true });
    // var allocator = std.heap.c_allocator;
    var allocator = std.heap.c_allocator;

    const app_data_dir_path_optional = get_data_dir: {
        if (std.fs.getAppDataDir(allocator, "popping-dikr")) |add| break :get_data_dir add else |err| switch (err) {
            std.fs.GetAppDataDirError.AppDataDirUnavailable => std.log.err("Error opening App data dir: 'AppDataDirUnavailable'\n", .{}),
            else => return err,
        }
        break :get_data_dir null;
    };
    defer allocator.free(app_data_dir_path_optional.?);

    if (app_data_dir_path_optional) |app_data_dir_path| blk: {
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
        config = std.zon.parse.fromSlice(Config, allocator, settings_file_content, &zon_parse_status, .{ .ignore_unknown_fields = true }) catch |err| switch (err) {
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

    errdefer |err| if (err == error.SdlError) std.log.err("SDL error: {s}", .{c.SDL_GetError()});

    // For programs that provide their own entry points instead of relying on SDL's main function
    // macro magic, 'SDL_SetMainReady' should be called before calling 'SDL_Init'.
    c.SDL_SetMainReady();

    try errify(c.SDL_SetAppMetadata("popping-dikr", "0.0.0", "dikr.popping-dikr.muslimDevCommunity"));

    try errify(c.SDL_Init(c.SDL_INIT_VIDEO));
    defer c.SDL_Quit();

    try errify(c.TTF_Init());
    defer c.TTF_Quit();

    errify(c.SDL_SetHint(c.SDL_HINT_RENDER_VSYNC, "1")) catch {};

    const window: *c.SDL_Window, const renderer: *c.SDL_Renderer = create_window_and_renderer: {
        var window: ?*c.SDL_Window = null;
        var renderer: ?*c.SDL_Renderer = null;
        try errify(c.SDL_CreateWindowAndRenderer("popping dikr", switch (config.window_type) { .fixed_width => config.window_w, .follow_height => (config.window_h / 6 * @as(c_int, @intCast(bismi_allah.len))) }, config.window_h, c.SDL_WINDOW_ALWAYS_ON_TOP | c.SDL_WINDOW_BORDERLESS, &window, &renderer));
        errdefer comptime unreachable;

        break :create_window_and_renderer .{ window.?, renderer.? };
    };
    defer c.SDL_DestroyRenderer(renderer);
    defer c.SDL_DestroyWindow(window);


    const font: *c.TTF_Font = open_font: {
        if(config.font_path) |path| blk: {
            break :open_font errify(c.TTF_OpenFont(path, 100)) catch break :blk;
        }
        const io: *c.SDL_IOStream = try errify(c.SDL_IOFromConstMem(font_data.ptr, font_data.len));
        break :open_font try errify(c.TTF_OpenFontIO(io, true, 100));
    };
    defer c.TTF_CloseFont(font);

    const surface = try errify(c.TTF_RenderText_Solid(font, @ptrCast(bismi_allah), bismi_allah.len, config.text_color));
    defer c.SDL_DestroySurface(surface);

    const texture = try errify(c.SDL_CreateTextureFromSurface(renderer, surface));

    main_loop: while (true) {

        // Process SDL events
        {
            var event: c.SDL_Event = undefined;
            while (c.SDL_PollEvent(&event)) {
                switch (event.type) {
                    c.SDL_EVENT_QUIT => {
                        break :main_loop;
                    },
                    c.SDL_EVENT_MOUSE_BUTTON_DOWN => {
                        switch (event.button.button) {
                            c.SDL_BUTTON_LEFT => {},
                            else => {},
                        }
                    },
                    else => {},
                }
            }
        }
        // Draw
        {
            try errify(c.SDL_SetRenderDrawColor(renderer, config.bg_color.r, config.bg_color.g, config.bg_color.b, config.bg_color.a));

            try errify(c.SDL_RenderClear(renderer));

            // try errify(c.SDL_SetRenderScale(renderer, 2, 2));

            try errify(c.SDL_RenderTexture(renderer, texture, null, null));

            try errify(c.SDL_RenderPresent(renderer));
        }
    }
}

/// Converts the return value of an SDL function to an error union.
inline fn errify(value: anytype) error{SdlError}!switch (@typeInfo(@TypeOf(value))) {

    .bool => void,
    .pointer, .optional => @TypeOf(value.?),
    .int => |info| switch (info.signedness) {
        .signed => @TypeOf(@max(0, value)),
        .unsigned => @TypeOf(value),
    },
    else => @compileError("unerrifiable type: " ++ @typeName(@TypeOf(value))),
} {
    errdefer std.log.err("{s}", .{c.SDL_GetError()});
    
    return switch (@typeInfo(@TypeOf(value))) {
        .bool => if (!value) error.SdlError,
        .pointer, .optional => value orelse error.SdlError,
        .int => |info| switch (info.signedness) {
            .signed => if (value >= 0) @max(0, value) else error.SdlError,
            .unsigned => if (value != 0) value else error.SdlError,
        },
        else => comptime unreachable,
    };
}
