#version 410 compatibility

#include "/lib/blockIDs.glsl"

uniform sampler2D gtexture;
uniform sampler2D specular;
uniform float alphaTestRef = 0.1;

flat in int blockID;
int glowstone = FULL_EMITTER;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
/* RENDERTARGETS: 0,1,2,4,5 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec3 specMap;
layout(location = 4) out vec4 extractedColor;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	
	lightmapData = vec4(lmcoord, 0.0, 1.0);
	encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
	if (color.a < alphaTestRef) {
		discard;
	}
	color.rgb = pow(color.rgb, vec3(2.2));
	
	if(blockID == METAL)
	{

	}


	extractedColor = color;
	specMap = texture(specular, texcoord).rgb;
	
}