#version 330 core

layout(location = 0) out vec4 frag_color;

uniform sampler2D tex;

in vec4 out_color;
in vec2 out_texcoord;

void main() {
	frag_color = texture(tex, out_texcoord) * out_color;
}
