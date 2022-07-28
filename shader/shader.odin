package shader

import gl "vendor:OpenGL"
import "core:fmt"

Program :: struct {
	id: u32,
	uniforms: gl.Uniforms,
}

Create_Program :: proc(vertex: string, fragment: string) -> Program {

	program, program_ok := gl.load_shaders_source(vertex, fragment);
	if !program_ok {
        fmt.eprintln("Failed to compile shaders!");
		return Program{}
    }

	sdr := Program { id = program }
	// Do we need to bind the program one creation time? --- Question
	// Bind_Program(sdr)

	// TODO (David): Free uniforms buffer when program is destroyed
	// NOTE: Maybe we should cache the uniforms here? === Question
	// Read_Uniforms_From_Program(sdr)
	return sdr 
}

Get_Uniform_Location :: proc(program: ^Program, name: string) -> i32 {
	return program.uniforms[name].location
}

Read_Uniforms_From_Program :: proc(program: ^Program) {
	program.uniforms = gl.get_uniforms_from_program(program.id)
}

Bind_Program :: proc(program: ^Program) {
	gl.UseProgram(program.id)
}

Unbind_Program :: proc() {
	gl.UseProgram(0)
}

Delete_Program :: proc(program: ^Program) {
	gl.DeleteProgram(program.id)
}

