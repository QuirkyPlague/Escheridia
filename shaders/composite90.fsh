#version 400 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"

//Full screen Reprojection

in vec2 texcoord;

const ivec2 offsets[9] = ivec2[9](
    ivec2( 0,  0),
    ivec2( 1,  0),
    ivec2(-1,  0),
    ivec2( 0,  1),
    ivec2( 0, -1),
    ivec2( 1,  1),
    ivec2(-1,  1),
    ivec2( 1, -1),
    ivec2(-1, -1)
);


/* RENDERTARGETS: 0,10 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 history;
void main() {
  color = texture(colortex0, texcoord);
  vec4 SpecMap = texture(colortex3, texcoord);
  float roughness = pow(1.0 - SpecMap.r, 2.0);
  #if TEMPORAL_REPROJECTION ==1
  float depth = texture(depthtex0, texcoord).r;
  const float handDepth = MC_HAND_DEPTH * 0.5 + 0.5;
  //main coords
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
  bool historyRejection = clamp(prevCoord,0,1) != prevCoord;

  float currentViewDepth = viewPos.z;
  float prevViewZ = projectAndDivide(gbufferProjectionInverse, vec3(prevCoord, previousDepth) * 2.0 - 1.0).z;
  float depthDelta = abs(currentViewDepth - prevViewZ);

  // threshold scales with distance to avoid far-plane flicker
  float depthThreshold = max(0.01, abs(currentViewDepth) * 0.01);

  float depthConfidence = clamp(1.0 - depthDelta / depthThreshold, 0, 1);

  vec2 texelSize = 1.0 / vec2(textureSize(colortex0, 0));
  float roughWeight = clamp((3.45 * (0.7 - pow(roughness, 7.8))),0,1);
  vec3 neighborhoodMin = vec3(1e20);
  vec3 neighborhoodMax = vec3(0.0);

  for (int i = 0; i < 9; i++) {
    vec2 uv = texcoord + vec2(offsets[i]) * texelSize;
    vec3 c = texture(colortex0, uv).rgb;

    neighborhoodMin = min(neighborhoodMin, c);
    neighborhoodMax = max(neighborhoodMax, c);
  }
  
  vec4 historyColor = texture(colortex10, prevCoord);

  #if SCREENSHOT_MODE == 0
  historyColor.rgb = clamp(historyColor.rgb, neighborhoodMin, neighborhoodMax);
  float historyWeight = TA_FACTOR * float(!historyRejection) ;
  historyWeight *= depthConfidence;
  color = mix(color, historyColor, historyWeight);
  #elif SCREENSHOT_MODE == 1
  if(hideGUI == true)
  {
  neighborhoodMin = vec3(0.0);
  neighborhoodMax = vec3(99999999999999.0);
  historyColor.rgb = clamp(historyColor.rgb, neighborhoodMin, neighborhoodMax);
  float historyWeight =0.995 * float(!historyRejection);
  historyWeight *= depthConfidence;
  color = mix(color, historyColor, historyWeight);
  }
  else
  {
  historyColor.rgb = clamp(historyColor.rgb, neighborhoodMin, neighborhoodMax);
  float historyWeight = TA_FACTOR * float(!historyRejection);
  historyWeight *= depthConfidence;
  color = mix(color, historyColor, historyWeight);
  }
  #elif SCREENSHOT_MODE == 2
    if(hideGUI == true)
  {
  neighborhoodMin = vec3(0.0);
  neighborhoodMax = vec3(99999999999999.0);
  historyColor.rgb = clamp(historyColor.rgb, neighborhoodMin, neighborhoodMax);
  float historyWeight =1.015 * float(!historyRejection);
  historyWeight *= depthConfidence;
  color = mix(color, historyColor, historyWeight);
  }
  else
  {
    historyColor.rgb = clamp(historyColor.rgb, neighborhoodMin, neighborhoodMax);
  float historyWeight = TA_FACTOR * float(!historyRejection);
  historyWeight *= depthConfidence;
  color = mix(color, historyColor, historyWeight);
  }
  #endif
  #endif

  
  history = color;
  
}
