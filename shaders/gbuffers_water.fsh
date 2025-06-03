#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/shadows/distort.glsl"
#include "/lib/shadows/drawShadows.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/blockID.glsl"

uniform sampler2D gtexture;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 modelPos;
in vec3 viewPos;
in vec3 feetPlayerPos;
flat in int blockID;
/* RENDERTARGETS: 0,1,2,4 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 waterMask;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	
	if (color.a < 0.1) {
		discard;
	}

	if(blockID == WATER_ID)
	{
    waterMask = vec4(1.0, 1.0, 1.0, 1.0);
    color.a *= 0.1;
	}
	else
	{
		waterMask = vec4(0.0, 0.0, 0.0, 1.0);
	}

	lightmapData = vec4(lmcoord, 0.0, 1.0);
	encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
	
	vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);

	vec3 shadow = getSoftShadow(shadowClipPos, feetPlayerPos, encodedNormal.rgb);

	vec3 diffuse = doDiffuse(texcoord, lightmapData.rg,encodedNormal.rgb,  worldLightVector, shadow);
	vec3 lighting = color.rgb * diffuse;
	color = vec4(lighting, color.a);

}