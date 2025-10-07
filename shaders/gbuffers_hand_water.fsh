#version 400 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/shadows/distort.glsl"
#include "/lib/shadows/drawShadows.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/brdf.glsl"
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
in mat3 tbnMatrix;
/* RENDERTARGETS: 0,1,2,4,5,4 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 waterMask;
layout(location = 4) out vec4 specMap;
layout(location = 5) out vec4 translucentMask;
void main() {
  color = texture(gtexture, texcoord) * glcolor;

  if (color.a < 0.1) {
    discard;
  }

  if (blockID == WATER_ID) {
    waterMask = vec4(1.0, 1.0, 1.0, 1.0);
    color.a *= 0.1;
  } else if (blockID == TRANSLUCENT_ID) {
    translucentMask = vec4(1.0, 1.0, 1.0, 1.0);
  } else {
    waterMask = vec4(0.0, 0.0, 0.0, 1.0);
  }

  vec3 normalMaps = texture(normals, texcoord).rgb;
  normalMaps = normalMaps * 2.0 - 1.0;
  normalMaps.z = sqrt(1.0 - dot(normalMaps.xy, normalMaps.xy));
  vec3 mappedNormal = tbnMatrix * normalMaps;

  lightmapData = vec4(lmcoord, 0.0, 1.0);
  encodedNormal = vec4(mappedNormal * 0.5 + 0.5, 1.0);
  specMap = texture(specular, texcoord);

}
