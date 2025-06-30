#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/blockID.glsl"

uniform sampler2D gtexture;



in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in mat3 tbnMatrix;
in vec3 viewPos;
flat in int blockID;
in float emission;

/* RENDERTARGETS: 0,1,2,5,6,11,12,13 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 specMap;
layout(location = 4) out vec4 geoNormal;
layout(location = 5) out vec4 sssMask;
layout(location = 6) out vec4 bloom;
layout(location = 7) out vec4 metalMask;
void main() {
	
	color = texture(gtexture, texcoord) * glcolor  ;

	if(color.a < 0.1) discard;
	
	
	vec3 normalMaps = texture2DLod(normals, texcoord,0).rgb;
	normalMaps = normalMaps * 2.0 - 1.0;
	normalMaps.xy /= (254.0/255.0);
	normalMaps.z = sqrt(1.0 - dot(normalMaps.xy, normalMaps.xy));
	vec3 mappedNormal = tbnMatrix * normalMaps;
	
	geoNormal = vec4(normal * 0.5 + 0.5, 1.0);

	lightmapData = vec4(lmcoord, 0.0, 1.0);
	encodedNormal = vec4(mappedNormal * 0.5 + 0.5, 1.0);
	specMap = texture2DLod(specular, texcoord, 0);

	if(blockID == SSS_ID)
	{
    	sssMask = vec4(1.0, 1.0, 1.0, 1.0);
	}
	else
	{
		sssMask =vec4(0.0, 0.0, 0.0, 1.0);
	}
	if(blockID == METAL_ID )
	{
    	metalMask = vec4(1.0, 1.0, 1.0, 1.0);
	}
	else
	{
		metalMask =vec4(0.0, 0.0, 0.0, 1.0);
	}
	#if RESOURCE_PACK_SUPPORT == 1
		color += color * (emission * 1.15)  * EMISSIVE_MULTIPLIER;
	#endif
}