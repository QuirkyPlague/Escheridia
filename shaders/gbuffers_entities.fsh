#version 400 compatibility

#include "/lib/util.glsl"
#include "/lib/blockID.glsl"
#include "/lib/postProcessing.glsl"
uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in mat3 tbnMatrix;
flat in int blockID;
in float emission;

/* RENDERTARGETS: 0,1,2,3,4,6,7,9 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmap;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 specData;
layout(location = 4) out vec4 geoNormal;
layout(location = 5) out vec4 bloom;
layout(location = 6) out vec4 mask;
layout(location = 7) out vec4 ao;

void main() {
  color = texture(gtexture, texcoord) * glcolor;

  vec3 normalMaps = texture(normals, texcoord).rgb;
  normalMaps = normalMaps * 2.0 - 1.0;
  normalMaps.xy /= 254.0 / 255.0;
  normalMaps.z = sqrt(1.0 - dot(normalMaps.xy, normalMaps.xy));
  vec3 mappedNormal = tbnMatrix * normalMaps;

  lightmap = vec4(lmcoord, 0.0, 1.0);
  encodedNormal = vec4(mappedNormal * 0.5 + 0.5, 1.0);
  specData = texture(specular, texcoord);

  geoNormal = vec4(normal * 0.5 + 0.5, 1.0);
  if (color.a < alphaTestRef) {
    discard;
  }

  if (blockID == SSS_ID) {
    mask = vec4(1.0, 1.0, 1.0, 1.0);
  } else {
    mask = vec4(0.0, 0.0, 0.0, 1.0);
  }
 vec3 emissive = vec3(0.0);
  #ifdef HC_EMISSION
  vec3 greyAlbedo = CSB(color.rgb,1.0, 0.0,1.515);
  
  if (emission > 0) {
    emissive = color.rgb * emission ;
    emissive += max(luminance(greyAlbedo ), float(greyAlbedo));
    emissive *= max(0.65 * pow(emissive, vec3(1.3528)), 0.0);

    emissive = CSB(emissive, 1.0, 0.75, 1.0);
  }
  #endif
  color.rgb += emissive;
  ao.a = texture(normals,texcoord).z * 0.5 + 0.5;
  color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
}
