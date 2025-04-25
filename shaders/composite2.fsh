#version 330 compatibility

#include "/lib/util.glsl"
#include "/lib/spaceConversions.glsl"
#include "/lib/atmosphere/sky.glsl"
in vec3 normal;


uniform float near;


uniform float frameTime;
uniform float waterEnterTime;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  vec4 waterMask = texture(colortex8, texcoord);
 vec2 lightmap = texture(colortex1, texcoord).rg;
  int blockID = int(waterMask) + 100;

  bool isWater = blockID == WATER_ID;
  bool inWater = isEyeInWater == 1.0;
  
  float depth = texture(depthtex0, texcoord).r;
  float depth1 = texture(depthtex1, texcoord).r;
  
  vec3 encodedNormal = texture(colortex2, texcoord).rgb;
  vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
  normal = mat3(gbufferModelView) * normal;
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 viewDir = normalize(viewPos);
  vec3 reflectedColor = calcSkyColor((reflect(viewDir, normal)));

   vec3 feetPlayerPos = getFeetPlayerPos(viewPos);
    vec3 worldPos = getWorldPos(feetPlayerPos);

vec3 LightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * LightVector;
  vec3 V = normalize((-viewDir));
 vec3 absorption = vec3(0.7882, 0.8118, 0.1255);
  #if DO_WATER_FOG == 1
  // Fog calculations
  //float dist = length(viewPos) / far;
  float dist0 = length(screenToView(texcoord, depth));
  float dist1 = length(screenToView(texcoord, depth1));
  float dist = max(0, dist1 - dist0);

  vec3 inscatteringAmount = vec3(0.0275, 0.0431, 0.0941);
   vec3 inscatteringAmount2 = vec3(0.0667, 0.1373, 0.7686);

   if(inWater)
	{
    if(!isNight)
    {
    dist = dist0;
    vec3 absorptionFactor = exp(-absorption * WATER_FOG_DENSITY * (dist * 0.45) );
    color.rgb *= absorptionFactor;
    color.rgb += vec3(0.6471, 0.4784, 0.2824) * inscatteringAmount / absorption * (1.0 - absorptionFactor);
    }
    else if( isNight)
    {
    dist = dist0;
    vec3 absorptionFactor = exp(-absorption * WATER_FOG_DENSITY * (dist * 0.35) );
    color.rgb *= absorptionFactor;
    color.rgb += vec3(0.0392, 0.0588, 0.2039) * inscatteringAmount2 / absorption * (1.0 - absorptionFactor) * 0.01;
    }
  
	}
  #endif
 vec3 F0 = vec3(0.02);
  vec3 L = normalize(worldLightVector);
  vec3 H = normalize(V + L);


 if(!isWater && inWater)
 {
  #if DO_WATER_FOG == 0 
  color *= vec4(0.149, 0.3373, 0.7098, 1.0);
  #endif
  if (WATER_FOG_DENSITY == 0.0)
  {
    color *= vec4(0.149, 0.3373, 0.7098, 1.0);
  }
  

 }
 
}