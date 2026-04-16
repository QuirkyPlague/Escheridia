#include "/lib/util.glsl"
#include "/lib/blockID.glsl"
#include "/lib/postProcessing.glsl"


/*
struct VoxyFragmentParameters {
    vec4 sampledColour;
    vec2 tile;
    vec2 uv;
    uint face;
    uint modelId;
    vec2 lightMap;
    vec4 tinting;
    uint customId;//Same as iris's modelId
};
*/

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 normal;
layout(location = 2) out vec4 lightmap;

void voxy_emitFragment(VoxyFragmentParameters parameters) {
  vec4 color = parameters.sampledColour * parameters.tinting;
  normal.xyz = vec3(uint((parameters.face>>1)==2), uint((parameters.face>>1)==0), uint((parameters.face>>1)==1)) * (float(int(parameters.face)&1)*2-1);
  normal.xyz = normalize(normal.xyz);
  lightmap.xy = parameters.lightMap;


}