#version 400 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/blockID.glsl"
#include "/lib/water/waterFog.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = textureLod(colortex0, texcoord, 0);

  vec4 waterMask = texture(colortex5, texcoord);
float rain = texture(colortex8, texcoord).r;
  if(rain == 1.0) return;
  float depth = texture(depthtex0, texcoord).r;
  float depth1 = texture(depthtex1, texcoord).r;

  int blockID = int(waterMask) + 100;

  bool isWater = blockID == WATER_ID;
  vec2 lightmap = texture(colortex1, texcoord).rg;

  if (isWater && !inWater) {
    color.rgb = waterExtinction(color.rgb, texcoord, lightmap, depth, depth1);
  }
  if (inWater) {
    vec3 waterScatter = waterFog(color.rgb, texcoord, lightmap, depth);

    color.rgb = waterScatter;
  }
  
}

