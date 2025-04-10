#version 410 compatibility

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


/* RENDERTARGETS: 0,1,2,3,5,6,2*/
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 specMap;
layout(location = 4) out vec4 extractedColor;
layout(location = 5) out vec4 specularLighting;
layout(location = 6) out vec4 geoNormal;


void main() {
	color = texture(gtexture, texcoord) * glcolor;
	
	vec4 albedo = texture(gtexture, texcoord) * glcolor;

	lightmapData = vec4(lmcoord, 0.0, 1.0);
	
	if (color.a < alphaTestRef) {
		discard;
	}
	
	

	vec3 normalMaps = texture(normals, texcoord).rgb;
	normalMaps = normalMaps * 2 - 1;
	normalMaps.z = sqrt(1 - dot(normalMaps.xy, normalMaps.xy));
	vec3 mappedNormal = tbnMatrix * normalMaps;
	
	
	
	encodedNormal = vec4(mappedNormal * 0.5 + 0.5, 1.0);

	extractedColor = color;
	specMap = texture(specular, texcoord);
	
	color.rgb = pow(color.rgb, vec3(2.2));
specularLighting *= color;
	#if DO_RESOURCEPACK_EMISSION == 0
	
		color += color * emission * 2 * EMISSIVE_MULTIPLIER;
	
	#endif
}