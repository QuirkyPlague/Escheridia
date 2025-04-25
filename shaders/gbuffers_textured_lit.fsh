#version 330 compatibility

#include "/lib/util.glsl"

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

flat in int blockID;

in vec4 tangent;
in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in mat3 tbnMatrix;
in float emission;


/* RENDERTARGETS: 0,1,2*/
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 geoNormal;



void main() {
	color = texture(gtexture, texcoord) * glcolor;

	if (color.a < alphaTestRef) {
		discard;
	}

	lightmapData = vec4(lmcoord, 0.0, 1.0);
	geoNormal = vec4(normal * 0.5 + 0.5, 1.0);

}