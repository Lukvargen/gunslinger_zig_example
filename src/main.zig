const c = @import("c.zig");
const std = @import("std");
const expect = std.testing.expect;
const eql = std.mem.eql;


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


var vbo : c.gs_handle_gs_graphics_vertex_buffer_t = std.mem.zeroes(c.gs_handle_gs_graphics_vertex_buffer_t);
var pip : c.gs_handle_gs_graphics_pipeline_t = std.mem.zeroes(c.gs_handle_gs_graphics_pipeline_t);
var shader : c.gs_handle_gs_graphics_shader_t = std.mem.zeroes(c.gs_handle_gs_graphics_shader_t);


const v_src = 
    \\#version 330 core
    \\precision mediump float;
    \\layout(location = 0) in vec2 a_pos;
    \\void main()
    \\{
    \\   gl_Position = vec4(a_pos, 0.0, 1.0);
    \\}
;
const f_src = 
    \\#version 330 core
    \\precision mediump float;
    \\out vec4 frag_color;
    \\void main()
    \\{
    \\   frag_color = vec4(0.7, 0.3, 0.3, 1.0);
    \\}
;

var v_data = [_]f32{
    0.0, 0.5,
    -0.5, -0.5, 
    0.5, -0.5
};





pub fn app_init() callconv(.C) void
{
    
}

fn string_to_c_array() u8 {

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

    var actions = c.gs_graphics_clear_action_t {
        .flag = 0,
        .unnamed_0 = .{.color=[4]f32{0.1, 0.1, 0.1, 1.0}},
    };
    var clear = (c.gs_graphics_clear_desc_t) {
        .actions = &actions,
        .size = 0,
    };

    var verex_binds = (c.gs_graphics_bind_vertex_buffer_desc_t) {
        .buffer = vbo,
        .offset = 0,
        .data_type = 0,
    };
    var binds = std.mem.zeroes(c.gs_graphics_bind_desc_t);
    binds.vertex_buffers = .{.desc=&verex_binds, .size = 0};

    var draw_desc = std.mem.zeroes(c.gs_graphics_draw_desc_t);
    draw_desc.start = 0;
    draw_desc.count = 3;

    c.gs_graphics_renderpass_begin(&cb, c.GS_GRAPHICS_RENDER_PASS_DEFAULT);
        c.gs_graphics_set_viewport(&cb, 0, 0, fbsu32.x, fbsu32.y);
        c.gs_graphics_clear(&cb, &clear);
        c.gsi_draw(&gsi, &cb);
        c.gs_graphics_pipeline_bind(&cb, pip);
        c.gs_graphics_apply_bindings(&cb, &binds);
        c.gs_graphics_draw(&cb, &draw_desc);
    c.gs_graphics_renderpass_end(&cb);
        

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

    std.debug.print("Init\n", .{});

    cb = c.gs_command_buffer_new();
	gsi = c.gs_immediate_draw_new(c.gs_platform_main_window());

    var vbo_desc = std.mem.zeroes(c.gs_graphics_vertex_buffer_desc_t);
    vbo_desc.data = @ptrCast(?*anyopaque, &v_data[0]); //v_data,
    vbo_desc.size = v_data.len *  @sizeOf(f32);
    vbo = c.gs_graphics_vertex_buffer_create(&vbo_desc);

    var sources = [_]c.gs_graphics_shader_source_desc_t {
        c.gs_graphics_shader_source_desc_t {.type = c.GS_GRAPHICS_SHADER_STAGE_VERTEX, .source = v_src},
        c.gs_graphics_shader_source_desc_t {.type = c.GS_GRAPHICS_SHADER_STAGE_FRAGMENT, .source = f_src}
    };
    
    var buffer: [64]u8 = undefined;
    _ = try std.fmt.bufPrintZ(&buffer, "{s}", .{ "triangle" });
    shader = c.gs_graphics_shader_create (
        &(c.gs_graphics_shader_desc_t) {
            .sources = @ptrCast([*c]c.gs_graphics_shader_source_desc_t, &sources),
            .size = 2 * @sizeOf(c.gs_graphics_shader_source_desc_t),
            .name = buffer,
        },
    );

    _ = try std.fmt.bufPrintZ(&buffer, "{s}", .{ "a_pos" });
    var raster = std.mem.zeroes(c.gs_graphics_raster_state_desc_t);
    raster.shader = shader;
    var pip_desc = std.mem.zeroes(c.gs_graphics_pipeline_desc_t);
    pip_desc.raster = raster;
    var vertex_attrib_desc = [_]c.gs_graphics_vertex_attribute_desc_t {
        .{
            .format = c.GS_GRAPHICS_VERTEX_ATTRIBUTE_FLOAT2,
            .name = buffer,
            .stride = 0,
            .offset = 0,
            .divisor = 0,
            .buffer_idx = 0,
        }
    };
    pip_desc.layout = .{
        .attrs = &vertex_attrib_desc[0],
        .size = @sizeOf(c.gs_graphics_vertex_attribute_desc_t),
    };
    pip = c.gs_graphics_pipeline_create(&pip_desc);


   
    while (c.gs_app_is_running() != 0) {
        c.gs_frame();
    }
}

fn string_to_char64_null_term(str : *const [:0]u8) [64]u8 {
    var buffer: [64]u8 = undefined;
    _ = try std.fmt.bufPrintZ(&buffer, "{s}", .{ str });
}
