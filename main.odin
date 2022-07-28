package main

import "application"
import "shader"

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:time"

import SDL "vendor:sdl2"
import gl "vendor:OpenGL"

CLEAR_COLOR :: glm.vec4{47.0 / 255.0, 54.0 / 255.0, 64.0 / 255, 1.0}

WINDOW_WIDTH  :: 1080
WINDOW_HEIGHT :: 720

WINDOW_TITLE :: "David's OpenGL Playground"

// This is fine for now
Vertex :: struct {
    pos: glm.vec3,
	// uv: glm.vec2,
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

	app := application.Init_Application(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	if !application.Is_Okay(app) {
		fmt.eprintln("Failed to initialize application")
		return
	}

	defer application.Cleanup_Application(app)

	sprite_ent := Entity{
		flags = 0,
		id = 0,
		rotation = 0.0,
		program = shader.Create_Program(shader.VERTEX_SOURCE, shader.FRAGMENT_SOURCE),
		mesh = Mesh{
			vao = 0,
			vbo = 0,
			ebo = 0,
			vertices =  []Vertex{
				{ { -0.5,  0.5, 0.0 } },
				{ { -0.5, -0.5, 0.0 } },
				{ {  0.5, -0.5, 0.0 } },
				{ {  0.5,  0.5, 0.0 } },
			},
			indices = []u16{
				0, 1, 2,
				2, 3, 0,
			},
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

// 
// NOTE (David): This is for a texture UV coordinates, but we don't have one yet 
when false {
	gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, uv))
	gl.EnableVertexAttribArray(1)
}

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, sprite_ent.mesh.ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(sprite_ent.mesh.indices) * size_of(sprite_ent.mesh.indices[0]), raw_data(sprite_ent.mesh.indices), gl.STATIC_DRAW)
	
	start_tick := time.tick_now()
	
	loop: for {

		// TODO (David): Take care of this
		t := f32(time.duration_seconds(time.tick_since(start_tick)))

		// TODO (David): We need better way to manage input events
		for application.Pull_Event(app) {
			#partial switch application.Get_Event(app).type {
			case .KEYDOWN: #partial switch application.Get_KeyCode(app) { case .ESCAPE: break loop }
			case .QUIT: break loop
			}
		}

		// TODO (David): Move to it's component
		model := glm.identity(glm.mat4)
		model = model * glm.mat4Rotate({0, 1, 1}, t)

		view := glm.mat4LookAt({0, -1, 1}, {0, 0, 0}, {0, 0, 1})
		proj := glm.mat4Perspective(45, 1.3, 0.1, 100.0)
		
		// NOTE (David): It's okay for now to calculate the transform on CPU
		// but we need to move it to the GPU, when we will have lots of entities.
		sprite_ent.transform = proj * view * model
		
		// TODO (David): make better system to manage unifroms 
		gl.UniformMatrix4fv(shader.Get_Uniform_Location(&sprite_ent.program, "u_transform"), 1, false, &sprite_ent.transform[0, 0])
        gl.Uniform1f(shader.Get_Uniform_Location(&sprite_ent.program, "u_time"), t)

		// TODO (David): move rendering logic to separate component
		gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

		gl.ClearColor(CLEAR_COLOR.x, CLEAR_COLOR.y, CLEAR_COLOR.z, CLEAR_COLOR.w)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		
		gl.DrawElements(gl.TRIANGLES, i32(len(sprite_ent.mesh.indices)), gl.UNSIGNED_SHORT, nil)

		application.Swap_Buffers(app)
	}
}
