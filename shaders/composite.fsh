#version 410 compatibility

#include "/lib/util.glsl"
#include "/lib/spaceConversions.glsl"
#include "/lib/atmosphere/sky.glsl"
//vertex variables
in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;




//lighting variables
vec3 blocklightColor = vec3(0.8118, 0.6314, 0.5412);
 vec3 skylightColor = vec3(0.0471, 0.0941, 0.1451);
 vec3 sunlightColor = vec3(1.0, 0.749, 0.4627);
 vec3 morningSunlightColor = vec3(0.9216, 0.4353, 0.2588);
 vec3 moonlightColor = vec3(0.0824, 0.2039, 1.0);
 vec3 nightSkyColor = vec3(0.0902, 0.1373, 0.6314);
 vec3 morningSkyColor = vec3(0.7804, 0.5216, 0.2471);
 vec3 ambientColor = vec3(0.0353, 0.0353, 0.0353);
 vec3 nightBlockColor = vec3(0.0745, 0.0706, 0.0431);
 vec3 nightAmbientColor = vec3(0.051, 0.051, 0.051);
vec3 duskSunlightColor = vec3(0.8784, 0.298, 0.2471);
vec3 duskSkyColor = vec3(0.8353, 0.3725, 0.302);

vec3 LightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * LightVector;
vec4 waterNormal = texture(colortex15,texcoord);

 vec4 SpecMap = texture(colortex3, texcoord);
 vec4 waterMask = texture(colortex8, texcoord);
vec4 normalMap = texture(colortex2, texcoord);
  int blockID = int(waterMask) + 100;
  
  bool isWater = blockID == WATER_ID;
  bool inWater = isEyeInWater == 1.0;

//utilities
vec3 lighting;
vec3 sunluminance = vec3(0.2125, 0.7154, 0.0721);

const float sunPathRotation = SUN_ROTATION;
float waterRoughness = 235.0/255.0;

uniform float far;
uniform float near;

#if DO_SOFT_SHADOW == 1
//soft shadow calculation
  vec3 getSoftShadow(vec4 shadowClipPos){
  const float range = SHADOW_SOFTNESS / 2; // how far away from the original position we take our samples from
  const float increment = range / SHADOW_QUALITY; // distance between each sample

  float depth = texture(depthtex0, texcoord).r;
			
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  

  shadowClipPos = findShadowClipPos(feetPlayerPos);
        
 
 

  float noise = IGN(floor(gl_FragCoord.xy), frameCounter);

  float theta = noise * radians(360.0); // random angle using noise value
  float cosTheta = cos(theta);
  float sinTheta = sin(theta);

  mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta); // matrix to rotate the offset around the original position by the angle

   
  vec3 shadowAccum = vec3(0.0, 0.0, 0.0); // sum of all shadow samples
  int samples = 0;
 for(float x = -range; x <= range; x += increment){
    for (float y = -range; y <= range; y+= increment){
      vec2 offset = rotation * vec2(x, y) / shadowMapResolution; // offset in the rotated direction by the specified amount. We divide by the resolution so our offset is in terms of pixels
      vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0); // add offset
      offsetShadowClipPos.z -= 0.0015; // apply bias 
      offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
      vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w; // convert to NDC space
      vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
      shadowAccum += getShadow(shadowScreenPos); // take shadow sample
      samples++;
      
    }
  }
 return shadowAccum / float(samples); // divide sum by count, getting average shadow
}
#endif
 
  



/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;


void main() {
  color = texture(colortex0, texcoord);

  //depth calculation
  float depth = texture(depthtex0, texcoord).r;
   float depth1 = texture(depthtex1, texcoord).r;
  if(depth1 == 1.0)
			{
           color.rgb += applySky(color.rgb) * 0.4;    
			
				 return;
			}

 
	

  //Space Conversions
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 worldPos = feetPlayerPos + cameraPosition;
	
  //lightmap
  vec2 lightmap = texture(colortex1, texcoord).rg; // only need r and g component
	vec3 encodedNormal = normalMap.rgb;
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is out of unit length
	
  //shadows
  vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
  vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
  vec3  albedo = texture(colortex0, texcoord).rgb;
 
 float ao = normalMap.b;

 
 float metallic = HARDCODED_METAL;

 float metalness = SpecMap.g;
float emission = SpecMap.a;
 
 #if DO_RESOURCEPACK_EMISSION == 1
 
 if (emission >= 0.0/255.0 && emission < 255.0/255.0)
	{
		color += color * emission * 15 * EMISSIVE_MULTIPLIER;
  
	}
#endif
   

  #if DO_SOFT_SHADOW == 1
    vec3 shadow = getSoftShadow(shadowClipPos);
  #else
   shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);

  shadowClipPos.z -=  0.001; // bias
  shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz); // distortion
   shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
  vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
  vec3 shadow = getShadow(shadowScreenPos);
  #endif

  //water extinction
  float dist0 = length(screenToView(texcoord, depth));
  float dist1 = length(screenToView(texcoord, depth1));
  float dist = max(0, dist1 - dist0);
  float waterFactor = exp2(-WATER_FOG_DENSITY * (0.6 - dist));

  float nearDist = length(viewPos) * near;
  float farWaterFactor = exp(WATER_FOG_DENSITY * (1.0  - dist));

//blank variables for lighting
vec3 waterColor = vec3(0.0392, 0.0784, 0.3137);
vec3 waterTint = vec3(0.1804, 1.0, 0.9451);

 //Time of day changes

     vec3 sunlight;
    
	   vec3 skylight;
	   vec3 blocklight;
	   vec3 ambient;
 
 if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    sunlight = mix(morningSunlightColor, sunlightColor * 1.5, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 1.0) * shadow;
	  skylight = mix(morningSkyColor * 0.6, skylightColor, time) * lightmap.g * SKY_INTENSITY;
	  blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	  ambient = ambientColor;
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
    sunlight = mix(sunlightColor * 1.5, duskSunlightColor, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE ), 0.0, 1.0)  * shadow;
	   skylight = mix(skylightColor, duskSkyColor * 0.6, time) * lightmap.g * SKY_INTENSITY;
	   blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   ambient = ambientColor;
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(11500, 13000, float(worldTime));
    sunlight = mix(duskSunlightColor, moonlightColor * 0.4 , time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 3.0) * shadow;
	   skylight = mix(duskSkyColor * 0.6, nightSkyColor * 0.2, time) * lightmap.g * SKY_INTENSITY;
	   blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   ambient = ambientColor;
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23215, 24000, float(worldTime));
    sunlight = mix(moonlightColor * 0.4 ,morningSunlightColor, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 3.0) * shadow;
	   skylight = mix(nightSkyColor * 0.02, morningSkyColor * 0.6, time) * lightmap.g * NIGHT_SKY_INTENSITY;
	   blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   ambient = ambientColor;
  }
  
  //convert all lighting values into one value
	lighting = sunlight + skylight + blocklight + ambient;

 if(rainStrength <= 1.0 && rainStrength > 0.0)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    albedo = albedo / 3;
    float rainRoughness = 0.75;
    lighting = sunlight /9 + skylight /9 + blocklight / 2 + ambient / 9 + albedo;
    
  }
   else if(rainStrength >= 1.0 && rainStrength < 0.0)
  {
    float wetToDry = smoothstep(1.0, 0.0, float(rainStrength));
    albedo = albedo;
    
    lighting = sunlight  + skylight  + blocklight  + ambient  + albedo;
 
  }

vec3 currentSunlight = sunlight;
vec3 currentSkylight = skylight;
   
vec3 V = normalize(cameraPosition - worldPos);
 vec3 L = normalize(worldLightVector);
vec3 H = normalize(V + L);
 vec3 encodedViewNormal = texture(colortex2, texcoord).rgb;
  vec3 viewNormal = normalize((encodedViewNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
  viewNormal = mat3(gbufferModelView) * viewNormal;
 vec3 viewDir = normalize(viewPos);
  vec3 reflectedColor = calcSkyColor((reflect(viewDir, viewNormal)));
vec3 V2 = normalize(-viewDir);
vec3 F0 = vec3(0.04);

if(SpecMap.r >= 154.0/255.0)  
{
  if(SpecMap.g >= 180.0/255.0)
  {
     vec3 F  = fresnelSchlick(max(dot(viewNormal, V2),0.0), F0);
    color.rgb = mix(color.rgb,  lightmap.g * reflectedColor, F);
  }
 else
 {
    vec3 F  = fresnelSchlick(max(dot(viewNormal, V2),0.0), F0);
    color.rgb = mix(color.rgb,lightmap.g * 0.4 * reflectedColor, F);
 }
 
}

   if(inWater)
	{
    if(isWater)
    {
    color.rgb *= mix(lighting, waterTint, 1.0);
    }
    else{
      lighting = sunlight * 3 + skylight * 3 + blocklight + ambient * 4 * waterTint;
      color.rgb *= lighting;
    }
   
	}
  
  
   color.rgb *= lighting;
  
    }
