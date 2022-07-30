package main

import "core:fmt"
import "core:time"
import "core:log"

import SDL "vendor:sdl2"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"

import "engine"
import "engine/entity"
import "engine/shader"

col_to_clip :: proc(a: f32) -> f32 {
	return (a / 255.0)
}

CLEAR_COLOR := glm.vec4{col_to_clip(47.0), col_to_clip(54.0), col_to_clip(64.0), 0.5}

WINDOW_WIDTH  :: 1080
WINDOW_HEIGHT :: 720

WINDOW_TITLE :: "David's OpenGL Playground"

Vertex :: struct {
  pos: glm.vec3,
  uv: glm.vec2,
}

Material :: struct {
	program: shader.Program,
	texture: i32,
}

Mesh_Type :: enum {
	Cube,
	Sphere,
	Plane,
}

Mesh :: struct {
  vao      :  u32,
  vbo      :  u32,
  ebo      :  u32,
  vertices :  []Vertex,
  indices  :  []u16,
}

Geometry :: struct {
	mesh     :  Mesh,
	material :  Material
}

// NOTE (David):
// All this Entity stuff is just to make things managable. However, It is not the best way to do it.
// Currently we are shaving everything in the "Entity",
// which will result us having a very large struct, So we need to find a better way.
// Like an array of structs. Or something ... Because we are using a lot of memory and it's not cache-line friendly.
Entity :: struct {
  flags    :  u16,
  id       :  u32,
  rotation :  f32,
  program  :  shader.Program,
  mesh     :  Mesh,
  position :  glm.vec3,
  transform:  glm.mat4,
}

Camera :: struct {
  position :  glm.vec3,
	front    :  glm.vec3,
	up       :  glm.vec3,
}

main :: proc() {

	app := engine.Init_Application(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	if !engine.Is_Okay(app) {
		fmt.eprintln("Failed to initialize engine")
		return
	}

  logger_opts := log.Options {
    .Level,
    .Line,
     .Procedure,
  };

  context.logger = log.create_console_logger(opt = logger_opts);
  log.info("Starting Application...");

	defer engine.Cleanup_Application(app)

  vertices := []Vertex{
    // @Position            @UV
    {{ -1.0, -1.0,  1.0 }, { 1.0, 1.0 }},
    {{  1.0, -1.0,  1.0 }, { 1.0, 0.0 }},
    {{  1.0,  1.0,  1.0 }, { 0.0, 0.0 }},
    {{ -1.0,  1.0,  1.0 }, { 0.0, 1.0 }},
    // @Position            @UV
    {{ -1.0, -1.0, -1.0 }, { 1.0, 1.0 }},
    {{  1.0, -1.0, -1.0 }, { 1.0, 0.0 }},
    {{  1.0,  1.0, -1.0 }, { 0.0, 0.0 }},
    {{ -1.0,  1.0, -1.0 }, { 0.0, 1.0 }},
  }

  indices := []u16{
		// @Front
		0, 1, 2,
		2, 3, 0,

    // @Right
		1, 5, 6,
		6, 2, 1,

    // @Back
		7, 6, 5,
		5, 4, 7,

		// @Left
		4, 0, 3,
		3, 7, 4,

    // @Bottom
		4, 5, 1,
		1, 0, 4,

    // @Top
		3, 2, 6,
		6, 7, 3
  }

	cube_ent := Entity {
		flags = 0,
		id = 0,
		rotation = 0.0,
		program = shader.Create_Program(shader.VERTEX_SOURCE, shader.FRAGMENT_SOURCE),
		mesh = Mesh{
			vao = 0,
			vbo = 0,
			ebo = 0,
			vertices = vertices,
			indices = indices
		},
		position = glm.vec3{0.0, 0.0, 0.0},
		transform = glm.identity(glm.mat4)
	}

	cube_ent2 := Entity {
		flags = 0,
		id = 1,
		rotation = 0.0,
		program = shader.Create_Program(shader.VERTEX_SOURCE, shader.FRAGMENT_SOURCE),
		mesh = Mesh{
			vao = 0,
			vbo = 0,
			ebo = 0,
			vertices = vertices,
			indices = indices
		},
		position = glm.vec3{2.0, 0.0, 2.0},
		transform = glm.identity(glm.mat4)
	}

	cam_speed := 0.5
	cam := Camera{
		position = glm.vec3{ 0.0, 0.0,  3.0 },
		front    = glm.vec3{ 0.0, 0.0, -1.0 },
		up       = glm.vec3{ 0.0, 1.0,  0.0 }
  }

	// TODO (David): Orginze shader creation/destrution stuff
	shader.Bind_Program(&cube_ent.program)
	defer shader.Delete_Program(&cube_ent.program)

	shader.Bind_Program(&cube_ent2.program)
	defer shader.Delete_Program(&cube_ent2.program)

	shader.Read_Uniforms_From_Program(&cube_ent2.program);
	defer delete(cube_ent2.program.uniforms)

	shader.Read_Uniforms_From_Program(&cube_ent.program);
	defer delete(cube_ent.program.uniforms)

	// TODO (David): Take care of ths buffers, maybe move them to the entity?
	// - We need to have a way to track all allocated memory, and free it when we're done with it
	// - Probably a bump allocator or something would be a way to do
	gl.GenVertexArrays(1, &cube_ent.mesh.vao);
  defer gl.DeleteVertexArrays(1, &cube_ent.mesh.vao)

	gl.GenVertexArrays(1, &cube_ent2.mesh.vao);
  defer gl.DeleteVertexArrays(1, &cube_ent2.mesh.vao)

	gl.GenBuffers(1, &cube_ent.mesh.vbo)
  defer gl.DeleteBuffers(1, &cube_ent.mesh.vbo)

	gl.GenBuffers(1, &cube_ent2.mesh.vbo)
  defer gl.DeleteBuffers(1, &cube_ent2.mesh.vbo)

	gl.GenBuffers(1, &cube_ent.mesh.ebo)
	defer gl.DeleteBuffers(1, &cube_ent.mesh.vbo)

	gl.GenBuffers(1, &cube_ent2.mesh.ebo)
  defer gl.DeleteBuffers(1, &cube_ent2.mesh.vbo)

	gl.BindBuffer(gl.ARRAY_BUFFER, cube_ent.mesh.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(cube_ent.mesh.vertices) * size_of(cube_ent.mesh.vertices[0]), raw_data(cube_ent.mesh.vertices), gl.STATIC_DRAW)

	gl.BindBuffer(gl.ARRAY_BUFFER, cube_ent2.mesh.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(cube_ent2.mesh.vertices) * size_of(cube_ent2.mesh.vertices[0]), raw_data(cube_ent2.mesh.vertices), gl.STATIC_DRAW)

  gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
	gl.EnableVertexAttribArray(0)

  // NOTE (David): This is for a texture UV coordinates, but we don't have one yet
	gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, uv))
	gl.EnableVertexAttribArray(1)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, cube_ent.mesh.ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(cube_ent.mesh.indices) * size_of(cube_ent.mesh.indices[0]), raw_data(cube_ent.mesh.indices), gl.STATIC_DRAW)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, cube_ent2.mesh.ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(cube_ent2.mesh.indices) * size_of(cube_ent2.mesh.indices[0]), raw_data(cube_ent2.mesh.indices), gl.STATIC_DRAW)

	start_tick := time.tick_now()

	loop: for {

		// TODO (David): Take care of this
		t := f32(time.duration_seconds(time.tick_since(start_tick)))

		// TODO (David): We need better way to manage input events
		for engine.Pull_Event(app) {
			#partial switch engine.Get_Event(app).type {
			  case .KEYDOWN: #partial switch engine.Get_KeyCode(app) {
					case .ESCAPE: break loop
					case .a:
            cam.position -= glm.normalize(glm.cross(cam.front, cam.up)) * f32(cam_speed);
					case .d:
            cam.position += glm.normalize(glm.cross(cam.front, cam.up)) * f32(cam_speed);
					case .w:
					  cam.position += f32(cam_speed) * cam.front;
					case .s:
					  cam.position -= f32(cam_speed) * cam.front;
				}
			  case .QUIT: break loop
			}
		}

		// TODO (David): Move to it's component
    model := glm.identity(glm.mat4)
		model = model * glm.mat4Rotate({-1, -1, 0}, t)

		view := glm.mat4LookAt(cam.position, cam.position + cam.front, cam.up)

		aspect := f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT)
		proj := glm.mat4Perspective(45, aspect, 0.1, 1000.0)

		// NOTE (David): It's okay for now to calculate the transform on CPU
		// but we need to move it to the GPU, when we will have lots of entities.
		cube_ent.transform = proj * view * model

		// TODO (David): make better system to manage unifroms

		gl.UniformMatrix4fv(shader.Get_Uniform_Location(&cube_ent.program, "u_transform"), 1, false, &cube_ent.transform[0, 0])
    gl.Uniform1f(shader.Get_Uniform_Location(&cube_ent.program, "u_time"), t)

		// TODO (David): move rendering logic to separate component
		gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
		gl.Enable(gl.DEPTH_TEST)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.ClearColor(CLEAR_COLOR.x, CLEAR_COLOR.y, CLEAR_COLOR.z, CLEAR_COLOR.w)
		gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

		gl.DrawElements(gl.TRIANGLES, i32(len(cube_ent.mesh.indices)), gl.UNSIGNED_SHORT, nil)

		// Draw Call 2

    model2 := glm.identity(glm.mat4)
    cube_ent2.position = glm.vec3{ glm.cos(t * 2), glm.sin(t * 2), 0,}
    cube_ent2.position *= 2.5

    model2[0, 3]  = -cube_ent2.position.x
	  model2[1, 3]  = -cube_ent2.position.y
		model2[2, 3]  = -cube_ent2.position.z
		model2[3].yzx =  cube_ent2.position.yzx

		model2 = model2 * glm.mat4Rotate({0, -1, 0}, t)

		model2 = model2 * glm.mat4Rotate({-1, -1, 0}, t)
		model2 = model2 * glm.mat4Translate({cube_ent2.position.x, cube_ent2.position.y, cube_ent2.position.z})
		view2 := glm.mat4LookAt(cam.position, cam.position + cam.front, cam.up)

		cube_ent2.transform = proj * view2 * model2

		gl.UniformMatrix4fv(shader.Get_Uniform_Location(&cube_ent2.program, "u_transform"), 1, false, &cube_ent2.transform[0, 0])
    gl.Uniform1f(shader.Get_Uniform_Location(&cube_ent2.program, "u_time"), t)

		gl.DrawElements(gl.TRIANGLES, i32(len(cube_ent2.mesh.indices)), gl.UNSIGNED_SHORT, nil)

		engine.Swap_Buffers(app)
	}
}
