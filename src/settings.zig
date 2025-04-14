// بسم الله الرحمن الرحيم
// la ilaha illa Allah Mohammed Rassoul Allah
const std = @import("std");
const builtin = @import("builtin");
const dvui = @import("dvui");

const window_icon_png = @embedFile("zig-favicon.png");

const Config = @import("config.zig");
var config: Config = undefined;

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
    try dvui.label(@src(), "adjust the application settings", .{}, .{ .color_text = .{ .color = col } , .font_style = .caption_heading });

    // Tabs
    {
        const Data = struct {
            const Tabs = enum {
                window,
                colors,
                timing,
                font,
            };
            var tab: Tabs = .window;
        };

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
                    try dvui.label(@src(), "Alhamdo li Allah window stuff", .{}, .{ .expand = .both, .gravity_x = 0.5, .gravity_y = 0.5 });
                },
                .colors => {
                    try dvui.label(@src(), "Alhamdo li Allah colors stuff", .{}, .{ .expand = .both, .gravity_x = 0.5, .gravity_y = 0.5 });
                },
                .timing => {
                    try dvui.label(@src(), "Alhamdo li Allah timing stuff", .{}, .{ .expand = .both, .gravity_x = 0.5, .gravity_y = 0.5 });
                },
                .font => {
                    try dvui.label(@src(), "Alhamdo li Allah font stuff", .{}, .{ .expand = .both, .gravity_x = 0.5, .gravity_y = 0.5 });
                },
            }
        }
    }
}

