#version 330 core

layout(location = 0) in vec4 in_position;
layout(location = 1) in vec4 in_color;
layout(location = 2) in vec2 in_texcoord;

out vec2 out_texcoord;
out vec4 out_color;

void main() {
	out_color = in_color;
	out_texcoord = in_texcoord;
	gl_Position = in_position;
}
