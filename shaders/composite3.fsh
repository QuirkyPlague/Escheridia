#version 330 compatibility

//includes
#include "/lib/util.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/brdf.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/blockID.glsl"
//vertex variables
in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;






/* RENDERTARGETS: 0 */
layout(location=0)out vec4 color;

void main(){
	color=texture(colortex0,texcoord);
	
	float depth = texture(depthtex0, texcoord).r;
	if(depth ==1)
	{
		color+= texture(colortex8, texcoord);
	}
	color += texture(colortex10, texcoord) * vec4(0.4902, 0.4902, 0.4902, 0.346);
	
		
	
}
	
	
