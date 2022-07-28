package shader

VERTEX_SOURCE :: `

#version 460 core

layout(location=0) in vec3 a_position;
layout(location=1) in vec4 a_color;

out vec4 v_color;

uniform mat4 u_transform;

void main() {	
	gl_Position = u_transform * vec4(a_position, 1.0);
	v_color = a_color;
}

`

FRAGMENT_SOURCE :: `

#version 460 core

in vec4 v_color;
out vec4 o_color;

uniform float u_time;

void main() {
	o_color = v_color + vec4(sin(u_time), 0.5 * cos(u_time), 0.5, 1.0);
}

`

