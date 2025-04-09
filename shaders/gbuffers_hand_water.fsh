#version 410 compatibility

#include "/lib/util.glsl"
#include "/lib/water.glsl"
uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

flat in int blockID;

in vec4 tangent;
in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in mat3 tbnMatrix;

mat3 tbnNormalTangent(vec3 normal, vec3 tangent) {
    // For DirectX normal mapping you want to switch the order of these 
    vec3 bitangent = cross(tangent, normal);
    return mat3(tangent, bitangent, normal);
}

/* RENDERTARGETS: 4,1,2,3,5,8 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 specMap;
layout(location = 4) out vec4 extractedColor;
layout(location = 5) out vec4 waterMask;


void main() {
	color = texture(gtexture, texcoord) * glcolor;
	
	lightmapData = vec4(lmcoord, 0.0, 1.0);
	
	if (color.a < alphaTestRef) {
		discard;
	}
	color.rgb = pow(color.rgb, vec3(2.2));
	
	vec3 normalmap = texture(normals, texcoord).rgb;
	normalmap = normalmap * 2 - 1;
	normalmap.z = sqrt(1 - dot(normalmap.xy, normalmap.xy));
	vec3 mappedNormal = tbnMatrix * normalmap;
	
	if(blockID == WATER_ID)
	{
		waterMask = vec4(0.0, 0.0, 0.0, 1.0);

	}
	else
	{
		waterMask = vec4(1.0, 1.0, 1.0, 1.0);
	}

	encodedNormal = vec4(mappedNormal * 1 + 0.5, 1.0);
	
	
	
	extractedColor = color;
	specMap = texture(specular, texcoord);
	
}