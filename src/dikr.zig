// بسم الله الرحمن الرحيم
// la ilaha illa Allah Mohammed Rassoul Allah

const std = @import("std");
const c = @import("c.zig").c;

const font_data = @embedFile("KacstPoster.ttf");

const Config = @import("config.zig");

const adkar = [_][:0]u8{
    @constCast("\u{FEEA}\u{FEE0}\u{FEDF}\u{FE8D} \u{FEE2}\u{FEB4}\u{FE91}"),
    @constCast("\u{FEEA}\u{FEE0}\u{FEDF}\u{FE8D} \u{FEE6}\u{FEA4}\u{FE92}\u{FEB3}"),
    @constCast("\u{FEAA}\u{FEE4}\u{FEA4}\u{FEE3} \u{FEF0}\u{FEE0}\u{FECB} \u{FEEA}\u{FEE0}\u{FEDF}\u{FE8D} \u{FEF0}\u{FEE0}\u{FEBB}"),
    @constCast("\u{FEEA}\u{FEE0}\u{FEDF}\u{FE8D} \u{FEAE}\u{FED4}\u{FED0}\u{FE98}\u{FEB3}أ"),
    @constCast("\u{FEEA}\u{FEE0}\u{FEDF}\u{FE8D} ﻻإ \u{FEEA}\u{FEDF}إ ﻻ"),
    @constCast("\u{FEAE}\u{FE92}\u{FEDB}أ }\u{FEEA}\u{FEE0}\u{FEDF}\u{FE8D}"),
};

pub fn main() !void {
    var dikr_str: []u8 = undefined;
    dikr_str = adkar[0];

    // config = try std.zon.parse.fromSlice(Config, std.heap.c_allocator, config_zon, null, .{ .ignore_unknown_fields = true });
    // var allocator = std.heap.c_allocator;
    const allocator = std.heap.c_allocator;

    const config = Config.loadConfig(allocator);
    const window_width = switch (config.window_type) {
        .fixed_width => config.window_w,
        .follow_height => (config.window_h / 6 * @as(c_int, @intCast(dikr_str.len))),
    };

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

    while (true) {
        defer std.Thread.sleep(@as(usize, config.sleep_time_minutes) * 1_000_000_000 * 60);
        defer dikr_str = adkar[std.crypto.random.int(u8) % adkar.len];

        const window: *c.SDL_Window, const renderer: *c.SDL_Renderer = create_window_and_renderer: {
            var window: ?*c.SDL_Window = null;
            var renderer: ?*c.SDL_Renderer = null;
            try errify(c.SDL_CreateWindowAndRenderer("popping dikr", window_width, config.window_h, c.SDL_WINDOW_ALWAYS_ON_TOP | c.SDL_WINDOW_BORDERLESS, &window, &renderer));
            errdefer comptime unreachable;

            break :create_window_and_renderer .{ window.?, renderer.? };
        };
        defer c.SDL_DestroyRenderer(renderer);
        defer c.SDL_DestroyWindow(window);

        const shown_at = std.time.timestamp();

        {
            const display_id = try errify(c.SDL_GetDisplayForWindow(window));
            const dm: *c.SDL_DisplayMode = @ptrCast(@constCast(try errify(c.SDL_GetCurrentDisplayMode(display_id))));
            // defer allocator.free(dm);

            var x: c_int = undefined;
            var y: c_int = undefined;

            _ = try errify(c.SDL_GetWindowPosition(window, &x, &y));
            std.debug.print("alhamdo li Allah window pose (before change) : {{{d}, {d}}}\n", .{ x, y });

            try errify(c.SDL_SetWindowPosition(window, 12, @intFromFloat(@as(f32, @floatFromInt(dm.h)) * 0.3)));

            _ = try errify(c.SDL_GetWindowPosition(window, &x, &y));
            std.debug.print("alhamdo li Allah window pose (after change) : {{{d}, {d}}}\n", .{ x, y });
        }

        const font: *c.TTF_Font = open_font: {
            if (config.font_path) |path| blk: {
                break :open_font errify(c.TTF_OpenFont(path, 100)) catch break :blk;
            }
            const io: *c.SDL_IOStream = try errify(c.SDL_IOFromConstMem(font_data.ptr, font_data.len));
            break :open_font try errify(c.TTF_OpenFontIO(io, true, 100));
        };
        defer c.TTF_CloseFont(font);

        const surface = try errify(c.TTF_RenderText_Solid(font, @ptrCast(dikr_str), dikr_str.len, config.text_color));
        defer c.SDL_DestroySurface(surface);

        const texture = try errify(c.SDL_CreateTextureFromSurface(renderer, surface));

        window_loop: while (true) {

            // Process SDL events
            {
                var event: c.SDL_Event = undefined;
                while (c.SDL_PollEvent(&event)) {
                    switch (event.type) {
                        c.SDL_EVENT_QUIT, c.SDL_EVENT_MOUSE_BUTTON_DOWN => {
                            break :window_loop;
                        },
                        else => {},
                    }
                }

                if (std.time.timestamp() >= shown_at + config.display_time_seconds) break :window_loop;
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
