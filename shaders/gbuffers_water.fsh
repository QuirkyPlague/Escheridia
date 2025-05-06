#version 330 compatibility

//includes
#include "/lib/util.glsl"
#include "/lib/spaceConversions.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/shadows.glsl"
#include "/lib/brdf.glsl"
#include "/lib/lighting.glsl"
uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

flat in int blockID;

in vec4 tangent;
in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in mat3 tbnMatrix;
in vec3 modelPos;
in vec3 viewPos;
in vec3 feetPlayerPos;
mat3 tbnNormalTangent(vec3 normal, vec3 tangent) {
    // For DirectX normal mapping you want to switch the order of these 
    vec3 bitangent = cross(tangent, normal);
    return mat3(tangent, bitangent, normal);
}

/* RENDERTARGETS: 0,1,2,3,5,8,10,11 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 specMap;
layout(location = 4) out vec4 extractedColor;
layout(location = 5) out vec4 waterMask;
layout(location = 6) out vec4 geoNormal;
layout(location = 7) out vec4 translucentLighting;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	
	lightmapData = vec4(lmcoord, 0.0, 1.0);
	
	if (color.a < alphaTestRef) {
		discard;
	}
	vec3 normalmap = texture(normals, texcoord).rgb;
	normalmap = normalmap * 2 - 1;
	normalmap.z = sqrt(1 - dot(normalmap.xy, normalmap.xy));
	vec3 mappedNormal = tbnMatrix * normalmap;
	 
   float roughness;
   float waterRoughness = 15.0/255.0;
	if(blockID == WATER_ID)
	{
		float perceptualSmoothness = 1.0 - sqrt(waterRoughness);
    waterMask = vec4(1.0, 1.0, 1.0, 1.0);
    roughness = perceptualSmoothness;
    color = color * 0.7;
	}
	else
	{
		waterMask = vec4(0.0, 0.0, 0.0, 1.0);
	}

	encodedNormal = vec4(mappedNormal * 1 + 0.5, 1.0);
	
	
	
	extractedColor = color;
	specMap = texture(specular, texcoord);
	 vec3 LightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * LightVector;

  vec4  albedo = texture(gtexture, texcoord) * glcolor;
  //lightmap
  vec2 lightmap = lightmapData.rg;
 
 float emission = specMap.a;

 vec3 emissive;
 //calculate lab emission
 #if DO_RESOURCEPACK_EMISSION == 1
 
 if (emission >= 0.0/255.0 && emission < 255.0/255.0)
	{
		emissive += albedo.rgb * emission  * 5.0 * EMISSIVE_MULTIPLIER;
  
	}
	#endif

geoNormal = vec4(normal * 0.5 + 0.5, 1.0);

  //shadows
  vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
  vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
  vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
  
  //assign texture mappings
 
  float ao =  1.0;
 
  
 roughness = pow(1.0 - specMap.r, 2.0);

//calculations for reflections
  vec3 V = normalize(cameraPosition - feetPlayerPos);
  vec3 L = normalize(worldLightVector);
  vec3 H = normalize(V + L);

//calculate F0
  vec3 F0;
  if(specMap.g <= 229.0/255.0)
  {
    F0 = vec3(specMap.g);
  }
  else
  {
    F0 = albedo.rgb;
  }
  vec3 F  = fresnelSchlick(max(dot(H, V),0.0), F0);
    color.a *= float(1.0 - F);
  //final lighting calculation
  vec3 shadow = getSoftShadow(shadowClipPos, texcoord, geoNormal.rgb, feetPlayerPos);
  vec3 diffuse;
  vec3 sunlight;
  vec3 lighting;
  vec3 currentSunlight = getCurrentSunlight(sunlight, encodedNormal.rgb, shadow, worldLightVector);
  vec3 speculars = brdf(albedo.rgb, F0, L, currentSunlight, encodedNormal.rgb, H, V, roughness, specMap);
   
  diffuse = getDiffuse(texcoord,lightmap, encodedNormal.rgb, shadow);
  lighting = albedo.rgb * diffuse + speculars;
  color = vec4(lighting, color.a);
}