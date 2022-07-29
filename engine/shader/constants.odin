package shader

VERTEX_SOURCE :: `

#version 460 core

layout(location=0) in vec3 a_position;
layout(location=1) in vec2 a_uv;

out vec2 v_uv;

uniform mat4 u_transform;

void main() {
	gl_Position = u_transform * vec4(a_position, 1.0);
	v_uv = a_uv;
}

`

FRAGMENT_SOURCE :: `

#version 460 core

in vec2 v_uv;
out vec4 o_color;

uniform float u_time;

void main() {
	o_color = vec4(v_uv, 0.0, 1.0);// * vec4(sin(u_time), 0.5 * cos(u_time), 0.5, 1.0);
}

`

