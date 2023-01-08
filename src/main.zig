// c.zig for auto translated,  zig_gs.zig for pretranslated gs headers
//const c = @import("c.zig");
const c = @import("zig_gs.zig");

const std = @import("std");
const zeroInit = std.mem.zeroInit;

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
var u_time : c.gs_handle_gs_graphics_uniform_t = undefined;
var gui :c.gs_gui_context_t = undefined;
var gui_demo_open = true;

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
    \\uniform float u_time;
    \\void main()
    \\{
    \\   frag_color = vec4(0.7 + 0.2 * sin(u_time*3.14), 0.3, 0.3, 1.0);
    \\}
;

var v_data = [_]f32{
    0.0,  0.5,
   -0.5, -0.5, 
    0.5, -0.5
};

pub fn main() !void {
    
    var app = std.mem.zeroes(c.gs_app_desc_t);
    app.window = zeroInit(c.gs_platform_window_desc_t, .{
        .width = 800,
        .height = 800,
        .vsync = 1,
        .title = "Gunslinger | Zig",
    });
    app.init = app_init;
    app.update = app_update;
    app.shutdown = app_shutdown;

     _ = c.gs_create(app);
    std.debug.print("gs app created: {}\n", .{app});

    while (c.gs_app().*.is_running != 0) {
        c.gs_frame();
    }
}

pub fn app_init(...) callconv(.C) void
{
    cb = c.gs_command_buffer_new();
	gsi = c.gs_immediate_draw_new(c.gs_platform_main_window());
    gui = c.gs_gui_new(c.gs_platform_main_window());
    
    triangle_setup();
}

pub fn app_update(...) callconv(.C) void
{
    if (c.gs_platform_key_pressed(c.GS_KEYCODE_ESC)) {
        c.gs_quit();
    }

    var delta = c.gs_platform_delta_time();
    time += delta;
    
    var fbs_x : u32 = undefined;
    var fbs_y : u32 = undefined;
    // for some reason gs_platform_framebuffer_sizev gave garbage on linux
    c.gs_platform_framebuffer_size(c.gs_platform_main_window(), &fbs_x, &fbs_y);

    c.gsi_depth_enabled(&gsi, true);
    c.gsi_camera3D(&gsi, fbs_x, fbs_y);

    var i: i32 = 0;
    var xi: i32 = 0;
    while (xi < 4) : (xi += 1) {
        var yi: i32 = 0; 
        while (yi < 4) : (yi += 1) {
            var xf = @intToFloat(f32, xi);
            var yf = @intToFloat(f32, yi);
            i += 1;
            const x = xf - 2 + @sin((xf+yf*4.0) + time)*1.0;
            const y = yf - 2 + @cos((xf+yf*4.0) + time)*1.0;
            const z = -8.0;
            const hx = 0.5;
            const hy = 0.5;
            const hz = 0.5;

            const red = @floatToInt(u8, (xf*yf/16.0) * 255.0);

            c.gsi_box(&gsi, x, y, z, hx, hy, hz, red, 200.0, 20.0, 255, c.GS_GRAPHICS_PRIMITIVE_TRIANGLES);
        }
    }

    c.gsi_camera2D(&gsi, fbs_x, fbs_y);

    var str = string_to_char64_null_term("ms: {d:.3}", .{delta});
    c.gsi_text(&gsi, 5.0, 5.0, &str, 0, 0, 200, 200, 200, 255);

    var clear = zeroInit(c.gs_graphics_clear_desc_t, .{
        .actions = &[_]c.gs_graphics_clear_action_t {
            zeroInit(c.gs_graphics_clear_action_t, .{
                .unnamed_0 = .{.color=[4]f32{0.1, 0.1, 0.1, 1.0}},
            })
        }
    });

    var hints = zeroInit(c.gs_gui_hints_t, .{
        .framebuffer_size = c.gs_v2(@intToFloat(f32, fbs_x), @intToFloat(f32, fbs_y)),
        .viewport = .{.x = 0.0, .y = 0.0, .w = @intToFloat(f32, fbs_x), .h = @intToFloat(f32, fbs_y)}
    });
    c.gs_gui_begin(&gui, &hints); 
        _ = c.gs_gui_demo_window(&gui, .{.x = 50.0, .y = 50.0, .w = 200.0, .h= 400.0}, &gui_demo_open);
    c.gs_gui_end(&gui);

    c.gs_graphics_renderpass_begin(&cb, c.GS_GRAPHICS_RENDER_PASS_DEFAULT);
        c.gs_graphics_set_viewport(&cb, 0, 0, fbs_x, fbs_y);
        c.gs_graphics_clear(&cb, &clear);
        c.gsi_draw(&gsi, &cb);

        triangle_draw();
        c.gs_gui_render(&gui, &cb);
    c.gs_graphics_renderpass_end(&cb);
        
    // workaround for gs_graphics_command_buffer_submit(CB),
    // zig translate-c unable to translate correctly
    var api = c.gs_graphics().*.api;
    api.command_buffer_submit.?(&cb);
}

pub fn app_shutdown(...) callconv(.C) void
{
    std.debug.print("shutdown\n", .{});
}

fn triangle_setup() void {
    vbo = c.gs_graphics_vertex_buffer_create(
        &zeroInit(c.gs_graphics_vertex_buffer_desc_t, .{
            .data = @ptrCast(?*anyopaque, &v_data),
            .size = @sizeOf(f32) * v_data.len,
        })
    );

    var shader_sources = [_]c.gs_graphics_shader_source_desc_t {
        .{.type = c.GS_GRAPHICS_SHADER_STAGE_VERTEX, .source = v_src},
        .{.type = c.GS_GRAPHICS_SHADER_STAGE_FRAGMENT, .source = f_src}
    };
    shader = c.gs_graphics_shader_create(
        &(c.gs_graphics_shader_desc_t) {
            .name = string_to_char64_null_term("triangle", .{}),
            .sources = @ptrCast([*c]c.gs_graphics_shader_source_desc_t, &shader_sources),
            .size = shader_sources.len * @sizeOf(c.gs_graphics_shader_source_desc_t),
        },
    );

    u_time = c.gs_graphics_uniform_create(
        &zeroInit(c.gs_graphics_uniform_desc_t, .{
            .name = string_to_char64_null_term("u_time", .{}),
            .layout = &[_]c.gs_graphics_uniform_layout_desc_t {
                zeroInit(c.gs_graphics_uniform_layout_desc_t, .{
                    .type = c.GS_GRAPHICS_UNIFORM_FLOAT
                })
            }
        })
    );

    pip = c.gs_graphics_pipeline_create(
        &zeroInit(c.gs_graphics_pipeline_desc_t, .{
            .raster = zeroInit(c.gs_graphics_raster_state_desc_t, .{
                .shader = shader
            }),
            .layout = zeroInit(c.gs_graphics_vertex_layout_desc_t, .{
                .attrs = &[_]c.gs_graphics_vertex_attribute_desc_t {
                    zeroInit(c.gs_graphics_vertex_attribute_desc_t,
                    .{
                        .format = c.GS_GRAPHICS_VERTEX_ATTRIBUTE_FLOAT2,
                        .name = string_to_char64_null_term("a_pos", .{}),
                    })
                },
                .size = @sizeOf(c.gs_graphics_vertex_attribute_desc_t),
            }),
        })
    );
    
}

fn triangle_draw() void {
    var uniforms = [_]c.gs_graphics_bind_uniform_desc_t {
        zeroInit(c.gs_graphics_bind_uniform_desc_t, .{.uniform = u_time, .data = &time})
    };
    var verex_binds = c.gs_graphics_bind_vertex_buffer_desc_t {
        .buffer = vbo,
        .offset = 0,
        .data_type = 0,
    };
    var binds = std.mem.zeroes(c.gs_graphics_bind_desc_t);
    binds.vertex_buffers = .{.desc = &verex_binds, .size = 0};
    binds.uniforms = .{.desc = &uniforms, .size = @sizeOf(c.gs_graphics_bind_uniform_desc_t) * uniforms.len};

    var draw_desc = zeroInit(c.gs_graphics_draw_desc_t, .{
        .start = 0,
        .count = 3,
    });

    c.gs_graphics_pipeline_bind(&cb, pip);
    c.gs_graphics_apply_bindings(&cb, &binds);
    c.gs_graphics_draw(&cb, &draw_desc);
}


fn string_to_char64_null_term(comptime format : []const u8, args: anytype) [64]u8 {
    var buffer: [64]u8 = undefined;

    if (std.fmt.bufPrintZ(&buffer, format, args)) |result| {
        _ = result;
    } else |err| {
        std.debug.print("string_to_char64_null_term - error: {}\n", .{err});
    }
    return buffer;
}
