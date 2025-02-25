#version 410 compatibility

#include "/lib/util.glsl"

//vertex variables
in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;


//lighting variables
vec3 blocklightColor = vec3(0.9882, 0.749, 0.6275);
 vec3 skylightColor = vec3(0.1451, 0.2235, 0.2863);
 vec3 sunlightColor = vec3(1.0, 0.902, 0.6902);
 vec3 morningSunlightColor = vec3(0.9216, 0.4353, 0.2588);
 vec3 moonlightColor = vec3(0.3843, 0.4667, 1.0);
 vec3 nightSkyColor = vec3(0.0588, 0.0902, 0.451);
 vec3 morningSkyColor = vec3(0.7804, 0.5216, 0.2471);
 vec3 ambientColor = vec3(0.0667, 0.0667, 0.0667);
 vec3 nightBlockColor = vec3(0.0745, 0.0706, 0.0431);
 vec3 nightAmbientColor = vec3(0.051, 0.051, 0.051);
vec3 duskSunlightColor = vec3(0.8784, 0.298, 0.2471);
vec3 duskSkyColor = vec3(0.8353, 0.3725, 0.302);


 vec4 SpecMap = texture(colortex3, texcoord);


//utilities
vec3 lighting;
vec3 sunluminance = vec3(0.2125, 0.7154, 0.0721);

const float sunPathRotation = SUN_ROTATION;


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
      offsetShadowClipPos.z -= 0.0024; // apply bias 
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
 

/* RENDERTARGETS: 0,4 */
layout(location = 0) out vec4 color;


void main() {
  color = texture(colortex0, texcoord);
  

 
 
  float perceptualSmoothness = 1.0 - sqrt(SpecMap.r);
   
 float roughness = perceptualSmoothness;

  //depth calculation
  float depth = texture(depthtex1, texcoord).r;
  if(depth == 1.0)
			{
        
				 return;
			}

  //Sunlight location
	vec3 LightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * LightVector;

  //Space Conversions
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  
	
  //lightmap
  vec2 lightmap = texture(colortex1, texcoord).rg; // only need r and g component
	vec3 encodedNormal = texture(colortex2, texcoord).rgb;
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is out of unit length
	
  //shadows
  vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
  vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
  vec3  albedo = texture(colortex0, texcoord).rgb;
  
  vec3 lightDir = worldLightVector;
  vec3 viewDir = mat3(gbufferModelViewInverse) * -normalize(projectAndDivide(gbufferProjectionInverse, vec3(texcoord.xy, 0) * 2.0 - 1.0));
	vec3 halfwayDir = normalize(lightDir + viewDir);
  
 
  vec3 F0 = vec3(0.4);
  F0      = mix(F0, albedo, SpecMap.g);
 


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
  float dist = length(viewPos) / far;
  float waterFactor = exp(-WATER_FOG_DENSITY * (0.18 - dist));

  float nearDist = length(viewPos) * near;
  float farWaterFactor = exp(WATER_FOG_DENSITY * (1.0  - dist));

//blank variables for lighting
vec3 waterColor = vec3(0.0392, 0.0784, 0.3137);
vec3 waterTint = vec3(0.0039, 0.7686, 1.0);
 //Time of day changes

     vec3 sunlight = dot(sunlightColor, sunluminance) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 3.0) * shadow;
	   vec3 skylight = skylightColor * lightmap.g * 2* SKY_INTENSITY;
	   vec3 blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   vec3 ambient = ambientColor / 4;
 
 if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    sunlight = mix(morningSunlightColor, sunlight, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 3.0) * shadow;
	  skylight = mix(morningSkyColor / 18, skylightColor, time) * lightmap.g * SKY_INTENSITY;
	  blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	  ambient = ambientColor / 4;
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
    sunlight = mix(sunlightColor, duskSunlightColor, time) * clamp(dot(normal, worldLightVector ), 0.0, 3.0) * SUN_ILLUMINANCE * shadow;
	   skylight = mix(skylightColor, duskSkyColor /18, time) * lightmap.g * SKY_INTENSITY;
	   blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   ambient = ambientColor / 4;
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(11500, 13000, float(worldTime));
    sunlight = mix(duskSunlightColor, moonlightColor , time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 3.0) * shadow;
	   skylight = mix(duskSkyColor/ 18, nightSkyColor , time) * lightmap.g * SKY_INTENSITY;
	   blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   ambient = mix(ambientColor, nightAmbientColor , time);
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23215, 24000, float(worldTime));
    sunlight = mix(moonlightColor  ,morningSunlightColor, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 3.0) * shadow;
	   skylight = mix(nightSkyColor, morningSkyColor, time) * lightmap.g * NIGHT_SKY_INTENSITY;
	   blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   ambient = mix(nightAmbientColor, ambientColor , time);
  }

  //convert all lighting values into one value
	lighting = sunlight  + skylight * 2 + blocklight + ambient;

  if(isEyeInWater == 1)
  {
    lighting = sunlight+ skylight + blocklight + waterTint/2 ;
    color.rgb *= mix(lighting, waterColor, clamp(waterFactor, 0.1, 3.5));
  }

// reflectance equation
vec3 Lo = vec3(0.0);
    for(int i = 0; i < 36; ++i) 
    {
        // calculate per-light radiance
        float dist    = length(worldLightVector);
        float attenuation = PBR_ATTENUATION / (dist * dist);
        vec3 radiance    = sunlight * attenuation;  
        
        vec3 F  = fresnelSchlick(max(dot(halfwayDir, viewDir),0.0), F0);
        
           // cook-torrance brdf
        float NDF = DistributionGGX(normal, halfwayDir, roughness);       
        float G   = GeometrySmith(normal, viewDir, lightDir, roughness); 

        vec3 numerator    = NDF * G * F;
        float denominator = 7 * max(dot(normal, viewDir), 0.0) * max(dot(normal, worldLightVector), 0.0)  + 0.0001;
        vec3 spec     = numerator / denominator;  

        vec3 kS = F;
        vec3 kD = vec3(1.0) - kS;
        kD *= 1.0 - SpecMap.g;	  
        
          // add to outgoing radiance Lo
      float NdotL = max(dot(normal, lightDir), 0.0);        
      Lo += (kD * albedo / PI + spec) * radiance * NdotL;
    }

  vec3 color2 = lighting + Lo;

    color2 *= color2 / (color2 + vec3(0.0, 0.0, 0.0));
    color2 = pow(color2, vec3(1.0/2.2));
    
    color *= vec4(color2, 1.0);
  //final lighting calculation
   color.rgb *= lighting;
     
  
  
      
}