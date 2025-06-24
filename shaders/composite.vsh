#version 420 compatibility

out vec2 texcoord;
#ifndef TILE_INDEX
#define TILE_INDEX 0
#endif
void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}