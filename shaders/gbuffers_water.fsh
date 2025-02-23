#version 410 compatibility

#include "/lib/distort.glsl"
#include "/lib/common.glsl"
#include "/lib/blockIDs.glsl"

uniform sampler2D gtexture;
uniform float alphaTestRef = 0.1;
uniform float far;

//view spaces
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;

//textures and atlases
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D noisetex;


//lighting variables
vec3 blocklightColor = vec3(0.9059, 0.3608, 0.0863);
 vec3 skylightColor = vec3(0.3569, 0.6588, 0.9059);
 vec3 sunlightColor = vec3(0.9216, 0.7961, 0.5804);
 vec3 morningSunlightColor = vec3(0.9216, 0.4353, 0.2588);
 vec3 moonlightColor = vec3(0.4471, 0.502, 0.8627);
 vec3 nightSkyColor = vec3(0.0588, 0.0902, 0.451);
 vec3 morningSkyColor = vec3(0.7804, 0.5216, 0.2471);
 vec3 ambientColor = vec3(0.0667, 0.0667, 0.0667);
 vec3 nightBlockColor = vec3(0.0745, 0.0706, 0.0431);
 vec3 nightAmbientColor = vec3(0.051, 0.051, 0.051);
vec3 duskSunlightColor = vec3(0.8588, 0.3333, 0.2549);
vec3 duskSkyColor = vec3(0.8353, 0.3725, 0.302);

float absorption;
vec3 WaterColor;
uniform int isEyeInWater;
vec3 lighting;
uniform int worldTime;
const int noiseTextureResolution = 4096;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;
flat in int blockID;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;

void main() {

color = texture(gtexture, texcoord) * glcolor * vec4(1.0, 1.0, 1.0, 0.856);
  
  lightmapData = vec4(lmcoord, 0.0, 1.0);
	encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
  
  float depth = texture(depthtex0, texcoord).r;
  if(depth == 0.0){
    return;
  }

  if(blockID == WATER_ID)
  {

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



//blank variables for lighting
vec3 sunlight = vec3(0.0);
vec3 skylight = vec3(0.0);
vec3 blocklight = vec3(0.0);
vec3 ambient = vec3(0);

 //Time of day changes
 if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
    sunlight = mix(morningSunlightColor, sunlightColor, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 3.0);
	  skylight = mix(morningSkyColor / 18, skylightColor, time) * lightmap.g * SKY_INTENSITY;
	  blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	  ambient = ambientColor / 4;
  }
  else if (worldTime >= 1000 && worldTime < 10000)
  {
     float time = smoothstep(1000, 10000, float(worldTime));
     	sunlight = mix(sunlightColor, sunlightColor, time) * clamp(dot(normal, worldLightVector ), 0.0, 3.0) * SUN_ILLUMINANCE;
	   skylight = mix(skylightColor, skylightColor, time) * lightmap.g * SKY_INTENSITY;
	   blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   ambient = ambientColor / 4;
 
  }
   else if (worldTime >= 10000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
    sunlight = mix(sunlightColor, duskSunlightColor, time) * clamp(dot(normal, worldLightVector ), 0.0, 3.0) * SUN_ILLUMINANCE;
	   skylight = mix(skylightColor, duskSkyColor /18, time) * lightmap.g * SKY_INTENSITY;
	   blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   ambient = ambientColor / 4;
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(11500, 13000, float(worldTime));
    sunlight = mix(duskSunlightColor, moonlightColor / 12, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 3.0);
	   skylight = mix(duskSkyColor/ 18, nightSkyColor / 14, time) * lightmap.g * SKY_INTENSITY;
	   blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   ambient = mix(ambientColor, nightAmbientColor /24, time);
  }
  else if (worldTime >= 13000 && worldTime < 23215)
  {
    sunlight = moonlightColor * clamp(dot(normal, worldLightVector * MOON_ILLUMINANCE), 0.0, 1.0);
	   skylight = lightmap.g * nightSkyColor  * SKY_INTENSITY;
	   blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   ambient = nightAmbientColor;
  }
   else if (worldTime >= 23215 && worldTime < 24000)
  {
    float time = smoothstep(23215, 24000, float(worldTime));
    sunlight = mix(moonlightColor / 3,morningSunlightColor, time) * clamp(dot(normal, worldLightVector * SUN_ILLUMINANCE), 0.0, 3.0);
	   skylight = mix(nightSkyColor/ 7, morningSkyColor/18, time) * lightmap.g * SKY_INTENSITY;
	   blocklight = lightmap.r * blocklightColor * LIGHT_INTENSITY;
	   ambient = mix(nightAmbientColor, ambientColor/4 , time);
  }

  //convert all lighting values into one value
	lighting = sunlight /3  + skylight/3 + blocklight /3;


  //final lighting calculation
	  color.rgb *= lighting   * pow(color.rgb, vec3(2.2));
}