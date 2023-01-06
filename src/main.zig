//const c = @import("c.zig");
const c =  @import("zig_gs.zig");
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
//var gui = std.mem.zeroes(c.gs_gui_context_t);

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
    0.0, 0.5,
    -0.5, -0.5, 
    0.5, -0.5
};

pub fn app_init() callconv(.C) void
{
    
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

    var i: i32 = 0;
    while (i < 100) : (i += 1) {
        const i_float = @intToFloat(f32, i);
        c.gsi_camera3D(&gsi, fbsu32.x, fbsu32.y);
        c.gsi_rotatev(&gsi, c.gs_deg2rad(13.254 * i_float + time * 25.0), c.GS_ZAXIS);
        c.gsi_rotatev(&gsi,  9273.254 * i_float + time * 1.0, c.GS_YAXIS);
        const x = 0.0;
        const y = 0.0;
        const z = -4.0;
        const hx = 0.5;
        const hy = 0.5;
        const hz = 0.5;

        const red =  @intCast(u8, @mod(200 + i * 25, 255));

        c.gsi_box(&gsi, x, y, z, hx, hy, hz, red, 255, 70, 255, c.GS_GRAPHICS_PRIMITIVE_TRIANGLES);
    }

    c.gsi_camera2D(&gsi, fbsu32.x, fbsu32.y);

    var str = string_to_char64_null_term("ms: {d:.3}", .{delta});
    c.gsi_text(&gsi, 5.0, 5.0, &str, 0, 0, 200, 200, 200, 255);

    var clear = zeroInit(c.gs_graphics_clear_desc_t, .{
        .actions = &[_]c.gs_graphics_clear_action_t {
            zeroInit(c.gs_graphics_clear_action_t, .{
                .unnamed_0 = .{.color=[4]f32{0.1, 0.1, 0.1, 1.0}},
            })
        }
    });

    c.gs_graphics_renderpass_begin(&cb, c.GS_GRAPHICS_RENDER_PASS_DEFAULT);
        c.gs_graphics_set_viewport(&cb, 0, 0, fbsu32.x, fbsu32.y);
        c.gs_graphics_clear(&cb, &clear);
        c.gsi_draw(&gsi, &cb);

        triangle_draw();
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

     _ = c.gs_create(app);
    std.debug.print("gs app created: {}\n", .{app});

    cb = c.gs_command_buffer_new();
	gsi = c.gs_immediate_draw_new(c.gs_platform_main_window());
    //c.gs_gui_init(&gui, c.gs_platform_main_window());
    
    triangle_setup();
    
    while (c.gs_app().*.is_running != 0) {
        c.gs_frame();
    }
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
