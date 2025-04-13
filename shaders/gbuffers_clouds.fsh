#version 410 compatibility


#include "/lib/util.glsl"

//received vertex variables
in vec2 texcoord;
in vec4 glcolor;
in vec2 lmcoord;
in vec3 normal;
uniform sampler2D gtexture;

//cloud colors
vec4 cloudColor = vec4 (0.0);
vec4 dayCloudColor = vec4(1.0, 1.0, 1.0, 0.444);
vec4 earlyCloudColor = vec4(1.0, 0.8, 0.6431, 0.9);
vec4 nightCloudColor = vec4(1.0, 1.0, 1.0, 1.0);
vec4 duskCloudColor = vec4(1.0, 0.6941, 0.5765, 0.9);

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;

void main() 
{
	color = texture(colortex0, texcoord) * glcolor;
	
 
lightmapData = vec4(lmcoord, 0.0, 1.0);
encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);

  	
color.rgb = pow(color.rgb, vec3(2.2));

}