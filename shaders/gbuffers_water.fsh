#version 400 compatibility

#include "/lib/lighting/lighting.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/postProcessing.glsl"
#include "/lib/blockID.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/shadows/SSAO.glsl"
uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in mat3 tbnMatrix;
in vec3 modelPos;
in vec3 viewPos;
in vec3 feetPlayerPos;
in vec3 worldPos;
flat in int blockID;
in float emission;

/* RENDERTARGETS: 0,1,2,3,4,5 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmap;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 specData;
layout(location = 4) out vec4 geoNormal;
layout(location = 5) out vec4 mask;


void main() {
  color = texture(colortex0, texcoord) * glcolor;
  
  vec3 normalMaps = texture(normals, texcoord, 0).rgb;
  normalMaps = normalMaps * 2.0 - 1.0;
  normalMaps.xy /= 254.0 / 255.0;
  normalMaps.z = sqrt(1.0 - dot(normalMaps.xy, normalMaps.xy));
  vec3 mappedNormal = tbnMatrix * normalMaps;

  lightmap = vec4(lmcoord, 0.0, 1.0);
  encodedNormal = vec4(mappedNormal * 0.5 + 0.5, 1.0);
  specData = texture(specular, texcoord);

 
  geoNormal = vec4(normal * 0.5 + 0.5, 1.0);
  if (color.a < 0.1) {
    discard;
  }
  vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
  vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
  vec3 viewDir = normalize(viewPos);
  vec3 V = normalize(cameraPosition - worldPos);
  vec3 L = normalize(worldLightVector);
  vec3 H = normalize(V + L);
  float VdotL = dot(normalize(feetPlayerPos), worldLightVector);

  bool isMetal = specData.g >= 230.0 / 255.0;

  //PBR
  float roughness = pow(1.0 - specData.r, 2.0);
  float sss = specData.b;
  float emission = specData.a;
  vec3 emissive = vec3(0.0);
  #ifndef HC_EMISSION
  if (emission < 1.0) {
    emission = min(emission, 1.0);
    emissive += color.rgb * emission;
    emissive += max(105.25 * pow(emissive, vec3(2.58)), 0.0);
      
    emissive = CSB(emissive, 1.0, 0.95, 1.0);
    //emissive = pow(emissive, vec3(2.2));
  }
#endif //HC_EMISSION

  vec3 shadow = getSoftShadow(shadowClipPos, geoNormal.rgb, sss);
  vec3 f0 = vec3(0.0);
  if (isMetal) {
    f0 = color.rgb;
  } else {
    f0 = vec3(specData.g);
  }
  float ao = texture(normals,texcoord).z * 0.5 + 0.5;

  if (blockID == WATER_ID) {
    mask = vec4(1.0, 1.0, 1.0, 1.0);
    #ifdef WAVES
    encodedNormal = geoNormal;
    #endif
    color.a *= 0.0;

  } else {
    mask = vec4(0.0, 0.0, 0.0, 1.0);

  }
 float ambientOcclusion = SSAO(viewPos, normal);
 //get voxel map position
  bool isEmissive = emission > 0;
  vec3 blocklight = vec3(0.0);
#ifdef FLOODFILL
  ivec3 voxel_pos = ivec3(feetPlayerPos-normal*.1+fract(cameraPosition)+VOXEL_RADIUS);
  //check if in voxel range
	if( clamp(voxel_pos,0,VOXEL_AREA) == voxel_pos )
	{
    //get data, unpack, visualize
		vec4 bytes = unpackUnorm4x8(texture(voxelMap, vec3(voxel_pos)/vec3(VOXEL_AREA)).r) ;
    vec4 bytes2 = unpackUnorm4x8(texture(voxelMap2, vec3(voxel_pos)/vec3(VOXEL_AREA)).r);
   

    vec3 smoothPos = vec3(feetPlayerPos + cameraPositionFract + VOXEL_RADIUS);
    
    
    float faceNdl = dot(mappedNormal.rgb, normalize(smoothPos));

    vec3 normalOffset = vec3(0.0);
			if (any(greaterThan(abs(geoNormal.rgb), vec3(1.0e-6))))
				normalOffset = 1.0 * (geoNormal.rgb);

			#if FLOODFILL_NORMAL_STRENGTH > 0
				vec3 texNormalOffset = -normalOffset + 5.0 *  mappedNormal.rgb;
				normalOffset = mix(normalOffset, texNormalOffset, (FLOODFILL_NORMAL_STRENGTH*0.01));
			#endif
      
    vec3 samplePos = smoothPos + 2.5 * mappedNormal.rgb;
    ivec3 doubleBufferWrite = mod(frameCounter,2) == 0 ? ivec3(0,VOXEL_AREA, 0) : ivec3(0);
    vec3 voxelColorLight = vec3(0.0);
    voxelColorLight = samplePos + vec3(doubleBufferWrite);
 
    bytes = texture(voxelFloodfill,vec3(voxelColorLight) / vec3(VOXEL_AREA, 2 * VOXEL_AREA, VOXEL_AREA)) * lightmap.r  ;
    bytes2 = texture(voxelFloodfill2,vec3(voxelColorLight) / vec3(VOXEL_AREA, 2 * VOXEL_AREA, VOXEL_AREA) ) * lightmap.r  ;
 
    
    
  vec3 combinedLight = bytes.rgb + bytes2.rgb ; 


    combinedLight = CSB(combinedLight, 1.0, 1.0, 1.0);
    
    float maxBrightness = MAX_FLOODFILL_INTENSITY ;  
   float currentBrightness = max(luminance(combinedLight), 1e-7);
    float blocklightLum = luminance(combinedLight * maxBrightness);
    combinedLight *= maxBrightness;
  
 
    const vec3 defaultBlocklight = vec3(1.0, 0.8, 0.5843);
    const float VOXEL_FADE_START = VOXEL_RADIUS / 1.45;
    const float VOXEL_FADE_END = VOXEL_RADIUS;
    float dist = length(viewPos);
    float fade = smoothstep(VOXEL_FADE_START, VOXEL_FADE_END, dist);
    blocklight.rgb = mix(combinedLight , defaultBlocklight * lightmap.r, fade);
   
 
   
    vec3 shadow = texture(shadowtex0, texcoord*100.).rgb;
    float shadowMask = (1.0 - step(0.01, texcoord.x)) * (1.0 - step(0.01, texcoord.y));
    color.rgb = mix(color.rgb, shadow, shadowMask);
}
else
{
  blocklight.rgb =  vec3(1.0, 0.8, 0.5843) * lightmap.r ;
}
#else
blocklight.rgb =  vec3(1.0, 0.8, 0.5843) * lightmap.r ;
#endif
 
   vec3 lighting = getLighting(
      color.rgb,
      lightmap.xy,
      mappedNormal.rgb,
      shadow,
      H,
      f0,
      roughness,
      V,
      ambientOcclusion,
      sss,
      VdotL,
      isMetal,
      ao,
      geoNormal.rgb,
      blocklight
    ) +
    emissive;
  


  color = vec4(lighting, color.a);
  float depth = texture(depthtex0, texcoord).r;
  vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz;
  //color = vec4(atmosphericFog(color.rgb, viewPos, depth, texcoord),color.a);
  color = vec4(borderFog(color.rgb, eyePlayerPos, depth), color.a);
  
  
}
