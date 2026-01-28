#ifndef FOG
#define FOG
#include "/lib/atmosphere/sky.glsl"
#include "/lib/shadows/distort.glsl"
#include "/lib/shadows/drawShadows.glsl"

vec3 borderFog(vec3 color, vec3 dir, float depth) {
  vec3 fogColor = skyScattering(normalize(dir));
  float dist = length(dir) / far;
  float fogFactor = exp(-24.0 * (1.0 - dist));
  float rainFogFactor = exp(-7.37 * (1.0 - dist));
  fogFactor = mix(fogFactor, rainFogFactor, wetness);
  return mix(color, fogColor, clamp(fogFactor, 0.0, 1.0));
}

vec3 atmosphericFog(vec3 color, vec3 viewPos, float depth, vec2 uv, bool isWater) {
  
  vec3 sunColor = vec3(0.0);

  vec3 absorption = vec3(0.9373, 0.9373, 0.9373);
  vec3 inscatteringAmount = computeSkyColoring(viewPos) * 3.43;
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 worldPos = feetPlayerPos + cameraPosition;
  float worldHeight = smoothstep(214, 0, worldPos.y);
  float fogSmoothReduction = smoothstep(1.0,0.38,worldHeight);
  float scatterReduce = smoothstep(0, 185, eyeBrightnessSmooth.y);
  inscatteringAmount = pow(inscatteringAmount, vec3(2.2));
  inscatteringAmount *= scatterReduce;
  absorption = pow(absorption, vec3(2.2));
  vec3 noiseOffset = vec3(0.12,0.0,0.73) * frameTimeCounter * 0.003;
  float noise = texture(fogTex,mod((worldPos.xz ) * noiseOffset.x , 1024.0) / 1024.0).r;
  
   float dist = length(viewPos) / far * (noise * 3);
  vec3 viewDir = normalize(viewPos);
  float smoothDepth = smoothstep(0.998, 1.0, depth);
  float VdotL = dot(viewDir, lightVector);
  float phase = CS(0.65, VdotL);
  float backPhase = CS(-0.15, VdotL);
  sunColor = currentSunColor(sunColor) * 12;
  float noiseDistributionFactor = smoothstep(1.0, 0.95, noise);
  vec3 absorptionFactor = exp(
    -absorption * (dist *0.313)
  );
 
   float fogDistFalloff = length(feetPlayerPos) / far;
  float fogReduction = exp( 0.5 * (-2.0 - fogDistFalloff));

  vec3 phaseLighting = sunColor  * phase  * scatterReduce * smoothDepth;
  phaseLighting *= fogReduction;
  vec3 scattering = inscatteringAmount * backPhase * worldHeight;
  vec3 totalScattering = (scattering + phaseLighting) * ENVIORNMENT_FOG_DENSITY;
  color.rgb *= absorptionFactor ;
  color.rgb += (totalScattering / absorption) * (1.0 - absorptionFactor) ;

  return color.rgb;
}



float noiseDensity(vec3 rayPos)
{   
     vec3 d = rayPos;
    vec2 uv = d.xy;

    float starScale =0.01;
    uv.x *= starScale;
    uv.y *= starScale;
    uv = fract(uv);
    vec2 position = uv * 3555.0 * 0.001 + 1.3 * 0.001;
    float density = 0.0;
    for(int i = 0; i < 12; i++)
    {
       float noise = texelFetch(cloudTex, ivec3(ivec2(position) % 128, i % 128), 0).r;
       density = max(0, noise - 0.35) * 1.0;
    }
   
     
    return density;
}


float getCloudDensity(vec3 pos, float dither, vec3 worldPos) {
  float density = 0.00;
  float weight = 0.0;
  
  
  pos = pos / 100;

  float noiseHeight = smoothstep(128, 64, worldPos.y);

  for (int i = 0; i < VL_ATMOSPHERIC_STEPS; i++) {
    float sampleWeight = exp2(-float(i));
    pos.xz += frameTimeCounter * 0.000025 * sqrt(i + 1);
    vec2 samplePos = pos.xy * exp2(float(i));
    
    float noise = texture(puddleTex, fract(samplePos)).r * sampleWeight;
    noise = mix(noise * 0.1, noise, noiseHeight);
    density += noise;
    weight += sampleWeight + dither;

   
  }
  density /= weight;



  density *= 0.4;

  return density;
}

vec3 VL_Atmospherics(vec3 start, vec3 end, vec3 pos, int stepCount, vec3 sceneCol, vec3 worldPos,  float dither)
{
  const float UNIFORM_PHASE = 1.0 / (4.0 * PI);

  vec3 rayPos = (end - start); 
  vec3 stepSize = rayPos * (1.0 / stepCount);
  float rayLength = length(rayPos);
  float rayLength2 = clamp(length(pos) + 1, 0, far);
  vec3 stepLength = rayLength + dither * stepSize;

  float worldLength = (length(worldPos));
  vec3 jitterWorld = worldPos + dither * (worldPos * (1.0 / stepCount));
  float fogHeight = smoothstep(32, 126, worldPos.y);
  float scatterReduce = smoothstep(0, 185, eyeBrightnessSmooth.y);
  vec3 sunColor = currentSunColor(vec3(0.0)) * 2;
  vec3 scatterColor = computeSkyColoring(vec3(0.0)) * 2.35 ;
  vec3 absColor = vec3(1.0);
  vec3 dir = normalize(pos);
  float VdotL = dot(dir, worldLightVector);
  float density;
  vec3 totalScatter;
    density = getCloudDensity(normalize(jitterWorld), dither, worldPos);
    float phase = CS(0.75, VdotL);
    float backPhase = CS(-0.1, VdotL); 
    vec3 frontScatter = sunColor * phase;
    vec3 backScatter = scatterColor * 7 * backPhase;
    vec3 fullScatter = frontScatter + backScatter;
  //marching loop
  for(int i = 0; i < stepCount; i++)
  {
    stepLength += stepSize;
    worldPos += jitterWorld;
   
    vec3 sampleScattering = fullScatter;
    vec3 sampleExtinction = (absColor + fullScatter);
    vec3 sampleOpticalDist = sampleExtinction * rayLength;
    vec3 sampleTransmission = exp(-sampleOpticalDist * density);
    
    float multipleScatRadius = sqrt(rayLength) + 1.0;
    vec3 fMS = (sampleScattering / sampleExtinction) * (1.0 - exp(-multipleScatRadius * sampleExtinction));
    vec3 sampleMSIrradiance = sunColor;
    sampleMSIrradiance *= UNIFORM_PHASE;
    sampleMSIrradiance *= fMS / (1.0 - fMS);
    
    vec3 sampleIrradiance = sunColor + scatterColor;
    sampleIrradiance += sampleMSIrradiance;
    vec3 sampleInscattering = sampleIrradiance * sampleScattering;
    vec3 scatteringIntegral = (sampleInscattering - sampleInscattering * sampleTransmission) / sampleExtinction;
    
    totalScatter =  scatteringIntegral;
  }
  float fogDistFalloff = length(pos) * 7.3;
  float fogReduction = exp(0.000325 * (-1.0 - fogDistFalloff));

  totalScatter = mix(totalScatter, totalScatter * 0.3, fogHeight) * fogReduction *scatterReduce;
  totalScatter *= 15;
  return totalScatter;
}

#endif //FOG
