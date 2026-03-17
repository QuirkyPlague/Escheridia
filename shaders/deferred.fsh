#version 430 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/shadows/SSAO.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 12 */
layout(location = 0) out float occlusion ;
void main() {
  occlusion = texture(colortex12, texcoord).r;
  occlusion = 1.0;
  float depth = texture(depthtex0, texcoord).r;

    if (depth == 1.0) {
    return;
  }
const float handDepth = MC_HAND_DEPTH * 0.5 + 0.5;
  
  vec3 screenPos = vec3(texcoord.xy, depth);
  vec3 NDCPos = vec3(texcoord, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 viewDir = normalize(viewPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  
  feetPlayerPos += cameraPosition;

  //reprojected coords
  feetPlayerPos -= previousCameraPosition;
  vec3 previousView = (gbufferPreviousModelView * vec4(feetPlayerPos, 1.0)).xyz;
  vec4 previousClip = gbufferPreviousProjection * vec4(previousView, 1.0);
  vec3 previousScreen = (previousClip.xyz / previousClip.w) * 0.5 + 0.5;
  vec2 prevCoord = previousScreen.xy;
  float previousDepth = texture(depthtex0, prevCoord).r;
 vec3 encodedNormal = texture(colortex2, texcoord).rgb;
  vec3 normal = normalize((encodedNormal - 0.5) * 2.0);
    vec3 surfNorm = texture(colortex4, texcoord).rgb;
  vec3 geoNormal = normalize((surfNorm - 0.5) * 2.0);
  bool historyRejection = clamp(prevCoord,0,1) != prevCoord;
  
   occlusion = SSAO(viewPos, geoNormal);

    #ifdef FILTER_AO
    float factor = SSAO_TA_FACTOR;
    bool rejectHistory = false;
    
    
    float sampleNDCDepth = depth * 2.0 - 1.0;
    float sampleViewDepth = gbufferProjectionInverse[3].z / (gbufferProjectionInverse[2].w * sampleNDCDepth + gbufferProjectionInverse[3].w);
    float prevViewZ = projectAndDivide(gbufferProjectionInverse, vec3(prevCoord, previousDepth) * 2.0 - 1.0).z;
    float depthDelta = abs(sampleViewDepth - prevViewZ);
    float depthThreshold = max(0.01, abs(prevViewZ) * 0.01);
    float depthConfidence = pow(clamp(1.0 - depthDelta / depthThreshold, 0, 1), 1.0); 
    
    float historyWeight = factor * float(!historyRejection)  * depthConfidence ;
   
    float previousOcclusion = texture(colortex12, prevCoord).r;
    occlusion = mix(occlusion, previousOcclusion, historyWeight);
   
   
    #endif
    
}
