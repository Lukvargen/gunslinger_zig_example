const c = @import("c.zig");
const std = @import("std");


var time: f32 = 0.0;

var cb: c.gs_command_buffer_t = undefined;
var gsi: c.gs_immediate_draw_t = undefined;

fn Vec2Of(comptime T: type) type {
    return struct {
        x: T,
        y: T,
    };
}
const Vec2u32 = Vec2Of(u32);
const Vec2i32 = Vec2Of(i32);
const Vec2f32 = Vec2Of(f32);


pub fn app_init() callconv(.C) void
{
    std.debug.print("Init\n", .{});

    cb = c.gs_command_buffer_new();
	gsi = c.gs_immediate_draw_new(c.gs_platform_main_window());
    
}

pub fn app_update() callconv(.C) void
{
    var delta = c.gs_platform_delta_time();
    time += delta;

    const fbs = c.gs_platform_framebuffer_sizev(c.gs_platform_main_window());

    const fbsu32 = Vec2u32 {
        .x = @floatToInt(u32, fbs.xy[0]),
        .y = @floatToInt(u32, fbs.xy[1]),
    };

    c.gsi_depth_enabled(&gsi, true);

    var i: f32 = 0;
    while (i < 100) : (i += 1) {

        c.gsi_camera3D(&gsi, fbsu32.x, fbsu32.y);
        c.gsi_rotatev(&gsi, c.gs_deg2rad(i * 13.254 + time * 25.0), c.GS_ZAXIS);
        c.gsi_rotatev(&gsi, i * 9273.254 + time * 1.0, c.GS_YAXIS);
        const x = 0.0;
        const y = 0.0;
        const z = -4.0;
        const hx = 0.5;
        const hy = 0.5;
        const hz = 0.5;

        const red =  @floatToInt(u8, @mod(200 + i * 25.0, 255));

        c.gsi_box(&gsi, x, y, z, hx, hy, hz, red, 255, 70, 255, c.GS_GRAPHICS_PRIMITIVE_TRIANGLES);
    }

    // print ms / frame
    const allocator = std.heap.page_allocator;
    var str = std.fmt.allocPrint(allocator, "ms: {d:.3}", .{delta}) catch "format failed";
    defer allocator.free(str);

    c.gsi_camera2D(&gsi, fbsu32.x, fbsu32.y);
    c.gsi_text(&gsi, 5.0, 5.0, str.ptr, 0, 0, 200, 200, 200, 255);

    c.gsi_renderpass_submit(&gsi, &cb, fbsu32.x, fbsu32.y, c.gs_color(10, 10, 10, 0));
    c.gs_graphics_command_buffer_submit(&cb);
}
pub fn app_shutdown() callconv(.C) void
{
    std.debug.print("shutdown\n", .{});
}

pub fn main() !void {
    
    var app = std.mem.zeroes(c.gs_app_desc_t);
    app.window_title = "Gunslinger | Zig";
    app.window_width = 800;
    app.window_height = 800;
    app.init = app_init;
    app.update = app_update;
    app.shutdown = app_shutdown;

    std.debug.print("App: {} \n", .{app});
    
    _ = c.gs_create(app);
    while (c.gs_app_is_running() != 0) {
        c.gs_frame();
    }
}
