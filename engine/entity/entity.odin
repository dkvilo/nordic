package entity

import "../shader"
import glm "core:math/linalg/glsl"

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

Ent :: struct {
  flags: u16,
  id: u32,
  rotation: f32,
  program: shader.Program,
  mesh: Mesh,
  position: glm.vec3,
  transform: glm.mat4,
}

// TODO (David): implement this later.
Create :: proc(id: i32, flags: u16) -> Ent {
  ent := Ent {
		flags = 0,
    id = 0,
    rotation = 0.0,
    program = shader.Create_Program(shader.VERTEX_SOURCE, shader.FRAGMENT_SOURCE),
		mesh = Mesh{
			vao = 0,
			vbo = 0,
			ebo = 0,
			vertices =  []Vertex{},
			indices = []u16{},
		},
		position = glm.vec3{0.0, 0.0, 0.0},
    transform = glm.identity(glm.mat4)
	}

  return ent
}

