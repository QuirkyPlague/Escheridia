#version 330 compatibility

#include "/lib/uniforms.glsl"
uniform sampler2D gtexture;



in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in mat3 tbnMatrix;
/* RENDERTARGETS: 0,1,2,3,5,6 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 godraySample;
layout(location = 4) out vec4 specMap;
layout(location = 5) out vec4 geoNormal;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	
	if (color.a < 0.1) {
		discard;
	}

	vec3 normalMaps = texture(normals, texcoord).rgb;
	normalMaps = normalMaps * 2.0 - 1.0;
	normalMaps.z = sqrt(1.0 - dot(normalMaps.xy, normalMaps.xy));
	vec3 mappedNormal = tbnMatrix * normalMaps;
	
	geoNormal = vec4(normal * 0.5 + 0.5, 1.0);

	lightmapData = vec4(lmcoord, 0.0, 1.0);
	encodedNormal = vec4(mappedNormal * 0.5 + 0.5, 1.0);
	specMap = texture(specular, texcoord);
}