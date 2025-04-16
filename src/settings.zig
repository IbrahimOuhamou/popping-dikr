// بسم الله الرحمن الرحيم
// la ilaha illa Allah Mohammed Rassoul Allah
const std = @import("std");
const builtin = @import("builtin");
const dvui = @import("dvui");

const window_icon_png = @embedFile("zig-favicon.png");

const Config = @import("config.zig");
var config: Config = undefined;

const Data = struct {
    const Tabs = enum {
        window,
        colors,
        timing,
        font,
    };
    var tab: Tabs = .window;
    var window_type: usize = 0;

    const window_type_names = blk: {
        const type_info = @typeInfo(Config.WindowType).@"enum";
        var temp: [type_info.fields.len][]const u8 = undefined;
        for (type_info.fields, 0..) |field, i| {
            temp[i] = field.name;
        }
        break :blk temp;
    };

    var text_color: dvui.Color = .{};
    var bg_color: dvui.Color = .{ .r = 0, .g = 0, .b = 0 };
    var font_path: ?[]u8 = undefined;
    var font_path_buffer: [std.fs.max_path_bytes:0]u8 = .{0} ** std.fs.max_path_bytes;

    var save_error_message: ?[]u8 = null;
};

// To be a dvui App:
// * declare "dvui_app"
// * expose the backend's main function
// * use the backend's log function
pub const dvui_app: dvui.App = .{
    .config = .{ .options = .{
        .size = .{ .w = 800.0, .h = 600.0 },
        .min_size = .{ .w = 250.0, .h = 350.0 },
        .title = "popping dikr settings",
        .icon = window_icon_png,
    } },
    .frameFn = AppFrame,
    .initFn = AppInit,
    .deinitFn = AppDeinit,
};
pub const main = dvui.App.main;
pub const std_options: std.Options = .{
    .logFn = dvui.App.logFn,
};

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_instance.allocator();

// Runs before the first frame, after backend and dvui.Window.init()
pub fn AppInit(win: *dvui.Window) void {
    _ = win;

    config = Config.loadConfig(gpa);
    Data.window_type = @intFromEnum(config.window_type);

    Data.text_color.r = config.text_color.r;
    Data.text_color.g = config.text_color.g;
    Data.text_color.b = config.text_color.b;

    Data.bg_color.r = config.bg_color.r;
    Data.bg_color.g = config.bg_color.g;
    Data.bg_color.b = config.bg_color.b;

    if (config.font_path) |font_path| @memcpy(Data.font_path_buffer[0..font_path.len], font_path);
}

// Run as app is shutting down before dvui.Window.deinit()
pub fn AppDeinit() void {}

// Run each frame to do normal UI
pub fn AppFrame() dvui.App.Result {
    frame() catch |err| {
        std.log.err("in frame: {!}", .{err});
        return .close;
    };
    return .ok;
}

pub fn frame() !void {
    var scroll = try dvui.scrollArea(@src(), .{}, .{ .expand = .both, .color_fill = .{ .name = .fill_window } });
    defer scroll.deinit();

    try dvui.label(@src(), "popping dikr settings", .{}, .{ .expand = .horizontal, .font_style = .title_1 });
    const col = dvui.Color.average(dvui.themeGet().color_text, dvui.themeGet().color_fill);
    try dvui.label(@src(), "adjust the application settings", .{}, .{ .color_text = .{ .color = col } , .font_style = .heading });

    // Tabs
    {
        var tbox = try dvui.box(@src(), .vertical, .{ .expand = .horizontal });
        defer tbox.deinit();

        {
            var tabs = dvui.TabsWidget.init(@src(), .{ .dir = .horizontal }, .{ .expand = .horizontal });
            try tabs.install();
            defer tabs.deinit();

            inline for (@typeInfo(Data.Tabs).@"enum".fields) |field| {
                var tab = try tabs.addTab(Data.tab == @as(Data.Tabs, @enumFromInt(field.value)), .{});
                defer tab.deinit();
                try dvui.label(@src(), field.name, .{}, .{});

                if (tab.clicked()) {
                    Data.tab = @as(Data.Tabs, @enumFromInt(field.value));
                }
            }
        }

        {
            var border = dvui.Rect.all(1);
            border.y = 0;
            var vbox3 = try dvui.box(@src(), .vertical, .{ .expand = .both, .background = true, .color_fill = .{ .name = .fill_window }, .border = border });
            defer vbox3.deinit();

            switch (Data.tab) {
                .window => {
                    try dvui.label(@src(), "Window Type:", .{}, .{ .expand = .both, .gravity_y = 0.5 });
                    if (try dvui.dropdown(@src(), &Data.window_type_names, &Data.window_type, .{})) config.window_type = @enumFromInt(Data.window_type);

                    {
                        try dvui.label(@src(), "Window Heigt: {d}px", .{config.window_h}, .{});
                        const result_window_h = try dvui.textEntryNumber(@src(), @TypeOf(config.window_h), .{ .value = &config.window_h }, .{});
                        if (result_window_h.value == .Valid) config.window_h = result_window_h.value.Valid;
                    }

                    {
                        try dvui.label(@src(), "Window Width: {d}px", .{config.window_w}, .{});
                        const result_window_w = try dvui.textEntryNumber(@src(), @TypeOf(config.window_w), .{ .value = &config.window_w }, .{});
                        if (result_window_w.value == .Valid) config.window_w = result_window_w.value.Valid;
                    }
                },
                .colors => {
                    try dvui.label(@src(), "Text Color", .{}, .{});
                    {
                        var hbox = try dvui.box(@src(), .horizontal, .{});
                        defer hbox.deinit();

                        var backbox = try dvui.box(@src(), .horizontal, .{ .min_size_content = .{ .w = 30, .h = 20 }, .background = true, .color_fill = .{ .color = Data.text_color }, .gravity_y = 0.5 });
                        backbox.deinit();

                        _ = try rgbSliders(@src(), &Data.text_color, .{ .gravity_y = 0.5 });
                    }


                    try dvui.label(@src(), "Backgroud Color", .{}, .{});
                    {
                        var hbox = try dvui.box(@src(), .horizontal, .{});
                        defer hbox.deinit();

                        var backbox = try dvui.box(@src(), .horizontal, .{ .min_size_content = .{ .w = 30, .h = 20 }, .background = true, .color_fill = .{ .color = Data.bg_color }, .gravity_y = 0.5 });
                        backbox.deinit();

                        _ = try rgbSliders(@src(), &Data.bg_color, .{ .gravity_y = 0.5 });
                    }

                    config.text_color.r = Data.text_color.r;
                    config.text_color.g = Data.text_color.g;
                    config.text_color.b = Data.text_color.b;

                    config.bg_color.r = Data.bg_color.r;
                    config.bg_color.g = Data.bg_color.g;
                    config.bg_color.b = Data.bg_color.b;
                },
                .timing => {
                    {
                        try dvui.label(@src(), "Display Time: {d} seconds", .{config.display_time_seconds}, .{});
                        const result_display_seconds = try dvui.textEntryNumber(@src(), @TypeOf(config.display_time_seconds), .{ .value = &config.display_time_seconds }, .{});
                        if (result_display_seconds.value == .Valid) config.display_time_seconds = result_display_seconds.value.Valid;
                    }

                    {
                        try dvui.label(@src(), "Sleep Time: {d} minutes", .{config.sleep_time_minutes}, .{});
                        const result_sleep_time = try dvui.textEntryNumber(@src(), @TypeOf(config.sleep_time_minutes), .{ .value = &config.sleep_time_minutes }, .{});
                        if (result_sleep_time.value == .Valid) config.sleep_time_minutes = result_sleep_time.value.Valid;
                    }
                },
                .font => {
                    try dvui.label(@src(), "Font:", .{}, .{});

                    var hbox3 = try dvui.box(@src(), .horizontal, .{});
                    defer hbox3.deinit();

                    var new_filename: ?[]const u8 = null;

                    if (try dvui.buttonIcon(@src(), "select font", dvui.entypo.folder, .{}, .{ .expand = .ratio, .gravity_x = 1.0 })) {
                        new_filename = try dvui.dialogNativeFileOpen(dvui.currentWindow().arena(), .{ .title = "Pick Font File", .filters = &.{ "*.ttf", "*.otf" } });
                    }

                    var te_file = try dvui.textEntry(@src(), .{ .text = .{ .buffer = &Data.font_path_buffer } }, .{.expand = .horizontal});
                    if (new_filename) |f| {
                        te_file.textLayout.selection.selectAll();
                        te_file.textTyped(f, false);
                    }
                    te_file.deinit();

                    Data.font_path = if(!std.mem.eql(u8, "", te_file.text)) te_file.text[0..te_file.len] else null;
                },
            }
        }
    }

    if (try dvui.button(@src(), "Save", .{}, .{})) {
        // free font path because:
        // 1, if it was set to null then there is no need to keep it
        // 2. if there is a new path, 
        if (config.font_path) |old_path| gpa.free(old_path);
        if (Data.font_path) |font_path| config.font_path = try gpa.dupeZ(u8, font_path);

        if (Data.save_error_message) |err_message| gpa.free(err_message);
        Data.save_error_message = try Config.saveConfig(gpa, config);

        if (Data.save_error_message) |message|
            try dvui.toast(@src(), .{ .message = message })
        else
            try dvui.toast(@src(), .{ .message = "Settings saved successfully all thanks to Allah" });

    }
}

// Let's wrap the sliderEntry widget so we have 3 that represent a Color
pub fn rgbSliders(src: std.builtin.SourceLocation, color: *dvui.Color, opts: dvui.Options) !void {
    var hbox = try dvui.box(src, .horizontal, opts);
    defer hbox.deinit();

    var red: f32 = @floatFromInt(color.r);
    var green: f32 = @floatFromInt(color.g);
    var blue: f32 = @floatFromInt(color.b);

    _ = try dvui.sliderEntry(@src(), "R: {d:0.0}", .{ .value = &red, .min = 0, .max = 255, .interval = 1 }, .{ .gravity_y = 0.5 });
    _ = try dvui.sliderEntry(@src(), "G: {d:0.0}", .{ .value = &green, .min = 0, .max = 255, .interval = 1 }, .{ .gravity_y = 0.5 });
    _ = try dvui.sliderEntry(@src(), "B: {d:0.0}", .{ .value = &blue, .min = 0, .max = 255, .interval = 1 }, .{ .gravity_y = 0.5 });

    color.r = @intFromFloat(red);
    color.g = @intFromFloat(green);
    color.b = @intFromFloat(blue);
}
