#version 430 compatibility

#include "/lib/util.glsl"
#include "/lib/blockID.glsl"
#include "/lib/postProcessing.glsl"
#include "/lib/shadows/SSAO.glsl"

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in mat3 tbnMatrix;
in vec3 viewPos;
flat in int blockID;
in float emission;
in vec3 feetPlayerPos;

/* RENDERTARGETS: 0,1,2,3,4,6,7,9 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmap;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 specData;
layout(location = 4) out vec4 geoNormal;
layout(location = 5) out vec4 bloom;
layout(location = 6) out vec4 mask;
layout(location = 7) out vec4 blocklight;

void main() {
  color = texture(gtexture, texcoord) * glcolor;


  vec3 normalMaps = texture(normals, texcoord).rgb;
 
  normalMaps = normalMaps * 2.0 - 1.0;
  normalMaps.xy /= 254.0 / 255.0;
  normalMaps.z = sqrt(1.0 - dot(normalMaps.xy, normalMaps.xy));
  vec3 mappedNormal = tbnMatrix * normalMaps;
  
   if(mappedNormal == vec3(0.0)) encodedNormal =  vec4(normal * 0.5 + 0.5, 1.0);
  lightmap = vec4(lmcoord, 0.0, 1.0);
  
  encodedNormal = vec4(mappedNormal * 0.5 + 0.5, 1.0);
  encodedNormal.a = texture(normals, texcoord).z * 0.5 + 0.5;
  specData = texture(specular, texcoord);
  
  geoNormal = vec4(normal * 0.5 + 0.5, 1.0);
  if (color.a < alphaTestRef) {
    discard;
  }

  if (blockID == SSS_ID) {
    mask = vec4(1.0, 1.0, 1.0, 1.0);
  } else {
    mask = vec4(0.0, 0.0, 0.0, 1.0);
  }
 vec3 emissive = vec3(0.0);
 vec3 greyAlbedo = CSB(color.rgb,1.0, 0.0,2.815);
  #ifdef HC_EMISSION
  

  if (emission > 0) {
    
    emissive = color.rgb * emission ;
    emissive += max(luminance(greyAlbedo ), float(greyAlbedo));
    emissive *= max(1.85 * pow(emissive, vec3(0.02528)), 0.0);

    emissive = CSB(emissive, 1.0, 0.95, 1.0);
    
  }
  #endif
  if(specData.a == 0.0 && emission > 0)
  {
     emissive = color.rgb * emission ;
    emissive += max(luminance(greyAlbedo ), float(greyAlbedo));
    emissive *= max(2.85 * pow(emissive, vec3(0.02528)), 0.0);

    emissive = CSB(emissive, 1.0, 0.95, 1.0);
  }
 
 color.rgb += emissive;
  //get voxel map position
  bool isEmissive = emission > 0;
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
			if (any(greaterThan(abs(normal.rgb), vec3(1.0e-6))))
				normalOffset = 3.0 * (normal.rgb);

			#if FLOODFILL_NORMAL_STRENGTH > 0
				vec3 texNormalOffset = -normalOffset + 15.0 *  mappedNormal.rgb;
				normalOffset = mix(normalOffset, texNormalOffset, (FLOODFILL_NORMAL_STRENGTH*0.01));
			#endif
      bool normalShouldBeGeo = mappedNormal.r < 1e-6 && mappedNormal.g < 1e-6;
      vec3 normalVal = mix(mappedNormal.rgb, geoNormal.rgb, float(normalShouldBeGeo));
    vec3 samplePos = smoothPos + normalOffset;
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
    
}
