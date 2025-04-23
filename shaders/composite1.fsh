#version 330 compatibility

//includes
#include "/lib/util.glsl"
#include "/lib/spaceConversions.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/shadows.glsl"
#include "/lib/brdf.glsl"
#include "/lib/lighting.glsl"

//vertex variables
in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;
vec3 geoNormal = texture(colortex10, texcoord).rgb;

//texture assignments and crucial bools
vec4 SpecMap = texture(colortex3, texcoord);
vec4 waterMask = texture(colortex8, texcoord);
vec4 normalMap = texture(colortex2, texcoord);
int blockID = int(waterMask) + 100;
bool isWater = blockID == WATER_ID;
bool inWater = isEyeInWater == 1.0;  

const float sunPathRotation = SUN_ROTATION;
const float waterRoughness = 235.0/255.0;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  vec3 LightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * LightVector;

  //depth calculation
  float depth = texture(depthtex0, texcoord).r;
   float depth1 = texture(depthtex1, texcoord).r;
  if(depth1 == 1.0)
			{
				  color.rgb += applySky(color.rgb, texcoord, depth);
         return;
			}
  
  //Space Conversions
	vec3 NDCPos = getNDC(texcoord, depth);
	vec3 viewPos = getViewPos(NDCPos);
	vec3 feetPlayerPos = getFeetPlayerPos(viewPos);
  vec3 worldPos = getWorldPos(feetPlayerPos);
	
  //lightmap
  vec2 lightmap = texture(colortex1, texcoord).rg;
  vec2 lightmap2 = texture(colortex1, texcoord).rg; // only need r and g component
	
  //normal
  vec3 encodedNormal = normalMap.rgb;
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is out of unit length
	vec3 geometryNormal = normalize((geoNormal - 0.5) * 2.0); // we normalize to make sure it is out of unit length
  //shadows
  vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
  vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
  vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
  
  //assign texture mappings
  vec3  albedo = texture(colortex0, texcoord).rgb;
  float ao = normalMap.b;
  float roughness;
  float perceptualSmoothness;
  
  if(isWater)
  {
    perceptualSmoothness = 1.0 - sqrt(waterRoughness);
    roughness = perceptualSmoothness;
  }
  else
  {
    roughness = pow(1.0 - SpecMap.r, 2.0);
  }
 

 float emission = SpecMap.a;

 vec3 emissive;
 //calculate lab emission
 #if DO_RESOURCEPACK_EMISSION == 1
 
 if (emission >= 0.0/255.0 && emission < 255.0/255.0)
	{
		emissive += albedo * emission * 5 * EMISSIVE_MULTIPLIER;
  
	}
#endif


//calculations for reflections
  vec3 V = normalize(cameraPosition - worldPos);
  vec3 L = normalize(worldLightVector);
  vec3 H = normalize(V + L);
  vec3 encodedViewNormal = texture(colortex2, texcoord).rgb;
  vec3 viewNormal = normalize((encodedViewNormal - 0.5) * 2.0); 
  viewNormal = mat3(gbufferModelView) * viewNormal;
  vec3 viewDir = normalize(viewPos);
  vec3 reflectedColor = calcSkyColor((reflect(viewDir, viewNormal)));
  vec3 V2 = normalize(-viewDir);

//calculate F0
  vec3 F0;
  if(SpecMap.g <= 229.0/255.0)
  {
    F0 = vec3(SpecMap.g);
  }
  else
  {
    F0 = albedo;
  }
    
  //final lighting calculation
  vec3 shadow = getSoftShadow(shadowClipPos, texcoord, geometryNormal);
  vec3 diffuse;
  vec3 sunlight;
  vec3 lighting;
  vec3 currentSunlight = getCurrentSunlight(sunlight, normal, shadow, worldLightVector);
  vec3 speculars = brdf(albedo, F0, L, currentSunlight, normal, H, V, roughness, SpecMap);
   
  diffuse = getDiffuse(texcoord,lightmap, normal, shadow, ao);
  lighting = albedo * diffuse + speculars + emissive;
  color.rgb = lighting;
  
  //reflections
  if(lightmap.g <= 0.2)
  {
    reflectedColor = albedo;
  }

  if(isWater && !inWater)
  {
    F0 = vec3(0.02);
    vec3 F  = fresnelSchlick(max(dot(viewNormal, V2),0.0), F0);
    color.rgb = mix(color.rgb, 0.26 * reflectedColor, F);
  }
    
  if(!inWater && !isWater)
  {
    if(SpecMap.r >= 145.0/255.0)
    {
      vec3 F  = fresnelSchlick(max(dot(viewNormal, V2),0.0), F0);
      color.rgb = mix(color.rgb, 0.26 * reflectedColor, F);
    }
  }
  
}
