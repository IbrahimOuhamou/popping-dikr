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

const screen_h: u16 = 0;
const screen_w: u16 = 0;

const config_zon =
    \\.{
    \\  .font_size = 80,
    \\
    \\  .bg_color = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
    \\  .text_color = .{ .r = 0, .g = 0, .b = 0, .a = 255 },
    \\
    \\  .sleep_time_minutes = 16,
    \\  .display_time_seconds = 5,
    \\}
;

const Config = struct {
    font_size: u8 = 80,

    bg_color: c.SDL_Color = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
    text_color: c.SDL_Color = .{ .r = 0, .g = 0, .b = 0, .a = 255 },

    sleep_time_minutes: u16 = 16,
    display_time_seconds: u16 = 5,
};

var config: Config = undefined;

const bismi_allah: [:0]const u8 = "ﻥﺎﻤﺣﺮﻟﺍ";

pub fn main() !void {
    config = try std.zon.parse.fromSlice(Config, std.heap.c_allocator, config_zon, null, .{ .ignore_unknown_fields = true });

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
        try errify(c.SDL_CreateWindowAndRenderer("popping dikr", @intCast(config.font_size * bismi_allah.len), config.font_size, 0, &window, &renderer));
        errdefer comptime unreachable;

        break :create_window_and_renderer .{ window.?, renderer.? };
    };
    defer c.SDL_DestroyRenderer(renderer);
    defer c.SDL_DestroyWindow(window);

    const font: *c.TTF_Font = try errify(c.TTF_OpenFont("res/KacstPoster.ttf", 100));
    defer c.TTF_CloseFont(font);

    const surface = try errify(c.TTF_RenderText_Solid(font, bismi_allah, bismi_allah.len, config.text_color));
    defer c.SDL_DestroySurface(surface);

    const texture = try errify(c.SDL_CreateTextureFromSurface(renderer, surface));

    const destination_rect = c.SDL_FRect{ .w = @floatFromInt(config.font_size * bismi_allah.len), .h = @floatFromInt(config.font_size), .x = 0, .y = 0 };

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

            try errify(c.SDL_RenderTexture(renderer, texture, null, &destination_rect));

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
