package main

import "engine"
import "engine/shader"

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:time"

import SDL "vendor:sdl2"
import gl "vendor:OpenGL"
import "engine/entity"

CLEAR_COLOR :: glm.vec4{47.0 / 255.0, 54.0 / 255.0, 64.0 / 255, 0.5}

WINDOW_WIDTH  :: 500
WINDOW_HEIGHT :: 500

WINDOW_TITLE :: "David's OpenGL Playground"

// This is fine for now
Vertex :: struct {
  pos: glm.vec3,
  uv: glm.vec2,
}

// We really don't need to have vao, vbo, and ebo here, but I'm lazy (We will refactor).
Mesh :: struct {
	vao, vbo, ebo: u32,
  vertices: []Vertex,
  indices: []u16,
}

// NOTE (David):
// All this Entity stuff is just to make things managable. However, It is not the best way to do it.
// Currently we are shaving everything in the "Entity",
// which will result us having a very large struct, So we need to find a better way.
// Like an array of structs. Or something ... Because we are using a lot of memory and it's not cache-line friendly.
Entity :: struct {
  flags: u16,
  id: u32,
  rotation: f32,
  program: shader.Program,
  mesh: Mesh,
  position: glm.vec3,
  transform: glm.mat4,
}

main :: proc() {

	app := engine.Init_Application(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	if !engine.Is_Okay(app) {
		fmt.eprintln("Failed to initialize engine")
		return
	}

	defer engine.Cleanup_Application(app)

  vertices := []Vertex{
    // @Position            @UV
    {{ -1.0, -1.0,  1.0 }, { 1.0, 1.0 }},
    {{  1.0, -1.0,  1.0 }, { 1.0, 0.0 }},
    {{  1.0,  1.0,  1.0 }, { 0.0, 0.0 }},
    {{ -1.0,  1.0,  1.0 }, { 0.0, 1.0 }},

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

	sprite_ent := Entity{
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

	// TODO (David): Orginze shader creation/destrution stuff
	defer shader.Delete_Program(&sprite_ent.program)
	shader.Bind_Program(&sprite_ent.program)

	shader.Read_Uniforms_From_Program(&sprite_ent.program);
	defer delete(sprite_ent.program.uniforms)

	// TODO (David): Take care of ths buffers, maybe move them to the entity?
	// - We need to have a way to track all allocated memory, and free it when we're done with it
	// - Probably a bump allocator or something would be a way to do
	gl.GenVertexArrays(1, &sprite_ent.mesh.vao);
  defer gl.DeleteVertexArrays(1, &sprite_ent.mesh.vao)

	gl.GenBuffers(1, &sprite_ent.mesh.vbo)
  defer gl.DeleteBuffers(1, &sprite_ent.mesh.vbo)

	gl.GenBuffers(1, &sprite_ent.mesh.ebo)
  defer gl.DeleteBuffers(1, &sprite_ent.mesh.vbo)

	gl.BindBuffer(gl.ARRAY_BUFFER, sprite_ent.mesh.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(sprite_ent.mesh.vertices) * size_of(sprite_ent.mesh.vertices[0]), raw_data(sprite_ent.mesh.vertices), gl.STATIC_DRAW)

  gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
	gl.EnableVertexAttribArray(0)

  // NOTE (David): This is for a texture UV coordinates, but we don't have one yet
	gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, uv))
	gl.EnableVertexAttribArray(1)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, sprite_ent.mesh.ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(sprite_ent.mesh.indices) * size_of(sprite_ent.mesh.indices[0]), raw_data(sprite_ent.mesh.indices), gl.STATIC_DRAW)

	start_tick := time.tick_now()

	loop: for {

		// TODO (David): Take care of this
		t := f32(time.duration_seconds(time.tick_since(start_tick)))

		// TODO (David): We need better way to manage input events
		for engine.Pull_Event(app) {
			#partial switch engine.Get_Event(app).type {
			  case .KEYDOWN: #partial switch engine.Get_KeyCode(app) { case .ESCAPE: break loop }
			  case .QUIT: break loop
			}
		}

		// TODO (David): Move to it's component
    model := glm.identity(glm.mat4)

    sprite_ent.position = glm.vec3{ glm.cos(t * 2), glm.sin(t * 2), 0,}
    sprite_ent.position *= 0.5

    model[0, 3] = -sprite_ent.position.x
	  model[1, 3] = -sprite_ent.position.y
		model[2, 3] = -sprite_ent.position.z
		model[3].yzx = sprite_ent.position.yzx

		model = model * glm.mat4Rotate({0, -1, 0}, t)
		view := glm.mat4LookAt({3, 3, 3}, {0, 0, 0}, {0, 1, 0})
		proj := glm.mat4Perspective(45, WINDOW_WIDTH / WINDOW_HEIGHT, 0.1, 1000.0)

		// NOTE (David): It's okay for now to calculate the transform on CPU
		// but we need to move it to the GPU, when we will have lots of entities.
		sprite_ent.transform = proj * view * model

		// TODO (David): make better system to manage unifroms
		gl.UniformMatrix4fv(shader.Get_Uniform_Location(&sprite_ent.program, "u_transform"), 1, false, &sprite_ent.transform[0, 0])
    gl.Uniform1f(shader.Get_Uniform_Location(&sprite_ent.program, "u_time"), t)

		// TODO (David): move rendering logic to separate component
		gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
		gl.Enable(gl.DEPTH_TEST)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.ClearColor(CLEAR_COLOR.x, CLEAR_COLOR.y, CLEAR_COLOR.z, CLEAR_COLOR.w)
		gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

		gl.DrawElements(gl.TRIANGLES, i32(len(sprite_ent.mesh.indices)), gl.UNSIGNED_SHORT, nil)

		engine.Swap_Buffers(app)
	}
}

