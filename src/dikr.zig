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

pub fn main() !void {
    errdefer |err| if (err == error.SdlError) std.log.err("SDL error: {s}", .{c.SDL_GetError()});

    // For programs that provide their own entry points instead of relying on SDL's main function
    // macro magic, 'SDL_SetMainReady' should be called before calling 'SDL_Init'.
    c.SDL_SetMainReady();

    try errify(c.SDL_SetAppMetadata("popping-dikr", "0.0.0", "dikr.popping-dikr.muslimDevCommunity"));

    try errify(c.SDL_Init(c.SDL_INIT_VIDEO));
    defer c.SDL_Quit();

    try errify(c.TTF_Init());
    defer c.TTF_Quit();

    const window_w = 640;
    const window_h = 480;
    errify(c.SDL_SetHint(c.SDL_HINT_RENDER_VSYNC, "1")) catch {};

    const window: *c.SDL_Window, const renderer: *c.SDL_Renderer = create_window_and_renderer: {
        var window: ?*c.SDL_Window = null;
        var renderer: ?*c.SDL_Renderer = null;
        try errify(c.SDL_CreateWindowAndRenderer("popping dikr", window_w, window_h, 0, &window, &renderer));
        errdefer comptime unreachable;

        break :create_window_and_renderer .{ window.?, renderer.? };
    };
    defer c.SDL_DestroyRenderer(renderer);
    defer c.SDL_DestroyWindow(window);

    const font = try errify(c.TTF_OpenFont("res/KacstPoster.ttf", 100));
    defer c.TTF_CloseFont(font);

    const bismi_allah: [:0]const u8 = "ﻥﺎﻤﺣﺮﻟﺍ";
    const surface = try errify(c.TTF_RenderText_Solid(font, bismi_allah, bismi_allah.len, c.SDL_Color{ .a = 255, .r = 255, .g = 255, .b = 255 }));
    defer c.SDL_DestroySurface(surface);

    const texture = try errify(c.SDL_CreateTextureFromSurface(renderer, surface));

    // const destination_rect = c.SDL_Rect{ .h = @intFromFloat(window_h * 0.5), .w = @intFromFloat(window_w * 0.5), .x = 12, .y = 12 };
    const destination_rect = c.SDL_FRect{ .h = 34, .w = 12 * bismi_allah.len, .x = 12, .y = 12 };

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
            try errify(c.SDL_SetRenderDrawColor(renderer, 0x47, 0x5b, 0x8d, 0xff));

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
