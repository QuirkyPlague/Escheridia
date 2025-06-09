#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/FXAA.glsl" 

in vec2 texcoord;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	
	float depth = texture(depthtex0, texcoord).r;
	if(depth==1.0)
	{
		color += texture(colortex8, texcoord);
		
	}

}