#version 400 compatibility

#include "/lib/lighting/lighting.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/postProcessing.glsl"
#include "/lib/blockID.glsl"

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in mat3 tbnMatrix;
in vec3 modelPos;
in vec3 viewPos;
in vec3 feetPlayerPos;
in vec3 worldPos;
flat in int blockID;

/* RENDERTARGETS: 0,1,2,3,4,5 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmap;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 specData;
layout(location = 4) out vec4 geoNormal;
layout(location = 5) out vec4 mask;

void main() {
  color = texture(gtexture, texcoord) * glcolor;

  vec3 normalMaps = texture(normals, texcoord, 0).rgb;
  normalMaps = normalMaps * 2.0 - 1.0;
  normalMaps.xy /= 254.0 / 255.0;
  normalMaps.z = sqrt(1.0 - dot(normalMaps.xy, normalMaps.xy));
  vec3 mappedNormal = tbnMatrix * normalMaps;

  lightmap = vec4(lmcoord, 0.0, 1.0);
  encodedNormal = vec4(mappedNormal * 0.5 + 0.5, 1.0);
  specData = texture(specular, texcoord);

  geoNormal = vec4(normal * 0.5 + 0.5, 1.0);
  if (color.a < 0.1) {
    discard;
  }
  vec3 viewDir = normalize(viewPos);
  vec3 V = normalize(cameraPosition - worldPos);
  vec3 L = normalize(worldLightVector);
  vec3 H = normalize(V + L);
  float VdotL = dot(normalize(feetPlayerPos), worldLightVector);

  bool isMetal = specData.g >= 230.0 / 255.0;

  //PBR
  float roughness = pow(1.0 - specData.r, 2.0);
  float sss = specData.b;
  float emission = specData.a;
  vec3 emissive = vec3(0.0);
  if (emission < 255.0 / 255.0) {
    emissive += color.rgb * emission;
    emissive += max(0.55 * pow(emissive, vec3(0.8)), 0.0);

    emissive += min(
      luminance(emissive * 6.05) * pow(emissive, vec3(1.25)),
      33.15
    );
    emissive = CSB(emissive, 1.0 * 1.0, 1.0, 1.0);
  }

  vec3 shadow = getSoftShadow(feetPlayerPos, geoNormal.rgb, sss);
  vec3 f0 = vec3(0.0);
  if (isMetal) {
    f0 = color.rgb;
  } else {
    f0 = vec3(specData.g);
  }
  float ao = texture(normals, texcoord).z;

  if (blockID == WATER_ID) {
    mask = vec4(1.0, 1.0, 1.0, 1.0);
    color.a *= 0.0;

  } else {
    mask = vec4(0.0, 0.0, 0.0, 1.0);

  }

  vec3 lighting = getLighting(
    color.rgb,
    lightmap.rg,
    mappedNormal.rgb,
    shadow,
    H,
    f0,
    roughness,
    V,
    ao,
    sss,
    VdotL,
    isMetal,
    normal
  );
 
  color = vec4(lighting, color.a);
}
