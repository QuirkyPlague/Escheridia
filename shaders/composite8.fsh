#version 410 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/sky.glsl"

//utilities
in vec2 texcoord;

vec3 blocklightColor = vec3(0.8118, 0.6314, 0.5412);
 vec3 skylightColor = vec3(0.0471, 0.0941, 0.1451);
 vec3 sunlightColor = vec3(1.0, 0.749, 0.4627);
 vec3 morningSunlightColor = vec3(0.9216, 0.4353, 0.2588);
 vec3 moonlightColor = vec3(0.3843, 0.4667, 1.0);
 vec3 nightSkyColor = vec3(0.0588, 0.0902, 0.451);
 vec3 morningSkyColor = vec3(0.7804, 0.5216, 0.2471);
 vec3 ambientColor = vec3(0.098, 0.098, 0.098);
 vec3 nightBlockColor = vec3(0.0745, 0.0706, 0.0431);
 vec3 nightAmbientColor = vec3(0.051, 0.051, 0.051);
vec3 duskSunlightColor = vec3(0.8784, 0.298, 0.2471);
vec3 duskSkyColor = vec3(0.8353, 0.3725, 0.302);

 vec4 SpecMap = texture(colortex3, texcoord);
 vec4 waterMask = texture(colortex8, texcoord);
vec4 normalMap = texture(colortex2, texcoord);
  int blockID = int(waterMask) + 100;
  
  bool isWater = blockID == WATER_ID;
  bool inWater = isEyeInWater == 1.0;


//soft shadow calculation
  vec3 getSoftShadow(vec4 shadowClipPos){
  const float range = SHADOW_SOFTNESS / 2; // how far away from the original position we take our samples from
  const float increment = range / SHADOW_QUALITY; // distance between each sample

  float depth = texture(depthtex0, texcoord).r;
			
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  

  //shadowClipPos = findShadowClipPos(feetPlayerPos);
        
 
 

  float noise = IGN(floor(gl_FragCoord.xy), frameCounter);

  float theta = noise * radians(360.0); // random angle using noise value
  float cosTheta = cos(theta);
  float sinTheta = sin(theta);

  mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta); // matrix to rotate the offset around the original position by the angle
 vec3 faceNormal;

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

/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 color;


void main() {
color = texture(colortex6, texcoord);

 float depth = texture(depthtex0, texcoord).r;
float waterRoughness = 235.0/255.0;
#if DO_RESOURCEPACK_PBR == 1

  float perceptualSmoothness = 1.0 - sqrt(SpecMap.r);
   #else
    float perceptualSmoothness = 1.0 - sqrt(HARDCODED_ROUGHNESS);
    
  #endif

   if(isWater)
  {
    perceptualSmoothness = 1.0 - sqrt(waterRoughness);
  }

  float roughness = perceptualSmoothness;

//Space Conversions
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 worldPos = feetPlayerPos + cameraPosition;
	
  //lightmap
  vec2 lightmap = texture(colortex1, texcoord).rg; // only need r and g component
	vec3 encodedNormal = normalMap.rgb;
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is out of unit length
	
 
  vec3  albedo = texture(colortex6, texcoord).rgb;
 vec3 LightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * LightVector;


 float ao = normalMap.b;

 
 float metallic = HARDCODED_METAL;

 float metalness = SpecMap.g;
//shadows
  vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
  vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
  

vec3 shadow = getSoftShadow(shadowClipPos);

//interpreted from https://learnopengl.com/PBR/Lighting
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
 
 #if DO_RESOURCEPACK_PBR == 1
  if(SpecMap.g <= 229.0/255.0)
  {
    F0 = vec3(SpecMap.g);
  }
  else
  {
    F0 = albedo;
  }
 #else
 F0      = mix(F0, albedo, metallic);
 #endif

 

 vec3 sunlight;
    
	   vec3 skylight = skylightColor * lightmap.g * 2* SKY_INTENSITY;
	   vec3 blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   vec3 ambient = ambientColor;
 
 if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    sunlight = mix(morningSunlightColor, sunlightColor, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 3.0) * shadow;
	  skylight = mix(morningSkyColor / 18, skylightColor, time) * lightmap.g * SKY_INTENSITY;
	  blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	  ambient = ambientColor / 4;
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
    sunlight = mix(sunlightColor, duskSunlightColor, time) * clamp(dot(normal, worldLightVector ), 0.0, 6.0) * SUN_ILLUMINANCE * shadow;
	   skylight = mix(skylightColor, duskSkyColor /18, time) * lightmap.g * SKY_INTENSITY;
	   blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   ambient = ambientColor / 4;
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(11500, 13000, float(worldTime));
    sunlight = mix(duskSunlightColor, moonlightColor / 12, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 3.0) * shadow;
	   skylight = mix(duskSkyColor/ 18, nightSkyColor / 14, time) * lightmap.g * SKY_INTENSITY;
	   blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   ambient = mix(ambientColor, ambientColor, time);
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23215, 24000, float(worldTime));
    sunlight = mix(moonlightColor /17,morningSunlightColor, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 3.0) * shadow;
	   skylight = mix(nightSkyColor/ 18, morningSkyColor/18, time) * lightmap.g * NIGHT_SKY_INTENSITY;
	   blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   ambient = mix(ambientColor, ambientColor , time);
  }
 if(lightmap.g <= 0.1 && !inWater)
  {
    sunlight = vec3(0.0);
    skylight = vec3(0.0);
  }
 vec3 currentSunlight = sunlight;
vec3 currentSkylight = skylight;
// reflectance equation
if(!inWater)
{
  vec3 Lo = vec3(0.0);
    for(int i = 0; i < 1; ++i) 
    {
      
        // calculate per-light radiance
        float dist    = length(worldLightVector);
        float attenuation = PBR_ATTENUATION / (dist * dist);
        vec3 radiance    = currentSunlight * attenuation ;  
        
      

        vec3 F  = fresnelSchlick(max(dot(H, V),0.0), F0);
        
           // cook-torrance brdf
        float NDF = DistributionGGX(normal, H, roughness);       
        float G   = GeometrySmith(normal, V, L, roughness); 

        vec3 numerator    = NDF * G * F;
        float denominator = 4.0 * dot(normal, V) * dot(normal, L)  + 0.0001;
        vec3 spec     = numerator / denominator;  
        vec3 kS = F;
        vec3 kD = vec3(1.0) - kS;
        #if DO_RESOURCEPACK_PBR == 1
        kD *= 1.0 - SpecMap.g;
        #else
         kD *= 1.0 - metallic;
        #endif
          // add to outgoing radiance Lo
      float NdotL = dot(normal, L);        
      Lo += (kD * albedo / PI + spec) * radiance * NdotL;
    
    vec3 ambient2 = vec3(0.03) * albedo;
   vec3 speculars =  ambient2 + Lo;
    speculars = speculars / (speculars + vec3(1.0, 1.0, 1.0));
    speculars = pow(speculars, vec3(1.0/2.2));
   
    
    
    color += vec4(speculars, 1.0);
  
   
    }  
}

}