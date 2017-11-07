#version 330 core

layout(location = 0) in vec4 vposition;
layout(location = 1) in vec2 vtexcoord;

out vec2 ftexcoord;

void main() {
	ftexcoord = vtexcoord;
	gl_Position = vposition;
}
