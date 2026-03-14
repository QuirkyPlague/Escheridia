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

/* RENDERTARGETS: 15,1,2,3,4,6,7,9 */
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
  
  
  lightmap = vec4(lmcoord, 0.0, 1.0);
  encodedNormal = vec4(mappedNormal * 0.5 + 0.5, 1.0);
  encodedNormal.a = texture(normals,texcoord).z * 0.5 + 0.5;
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
  #ifdef HC_EMISSION
  vec3 greyAlbedo = CSB(color.rgb,1.0, 0.0,2.915);

  if (emission > 0) {
    
    emissive = color.rgb * emission ;
    emissive += max(luminance(greyAlbedo ), float(greyAlbedo));
    emissive *= max(0.85 * pow(emissive, vec3(1.3528)), 0.0);

    emissive = CSB(emissive, 1.0, 0.95, 1.0);
    
  }
  #endif
 
  //get voxel map position

    #ifdef FLOODFILL
  ivec3 voxel_pos = ivec3(feetPlayerPos-normal*.1+fract(cameraPosition)+VOXEL_RADIUS);
  //check if in voxel range
	if( clamp(voxel_pos,0,VOXEL_AREA) == voxel_pos )
	{
    //get data, unpack, visualize
		vec4 bytes = unpackUnorm4x8(texture(voxelMap, vec3(voxel_pos)/vec3(VOXEL_AREA)).r);
    vec4 bytes2 = unpackUnorm4x8(texture(voxelMap2, vec3(voxel_pos)/vec3(VOXEL_AREA)).r);
   

    vec3 smoothPos = vec3(feetPlayerPos + cameraPositionFract + VOXEL_RADIUS);
    ivec3 doubleBufferWrite = mod(frameCounter,2) == 0 ? ivec3(0,VOXEL_AREA, 0) : ivec3(0);
    vec3 voxelColorLight = smoothPos + vec3(doubleBufferWrite);
    bytes = texture(voxelFloodfill,vec3(voxelColorLight) / vec3(VOXEL_AREA, 2 * VOXEL_AREA, VOXEL_AREA));
    bytes2 = texture(voxelFloodfill2,vec3(voxelColorLight) / vec3(VOXEL_AREA, 2 * VOXEL_AREA, VOXEL_AREA));

    vec3 orangeLight = bytes.r * vec3(1.0, 0.6314, 0.2157);
    vec3 blueLight =  bytes.g * vec3(0.2157, 0.7569, 0.8784);
    vec3 whiteLight = bytes.b * vec3(0.7098, 0.8784, 0.9294);
    vec3 redLight = bytes2.g * vec3(0.8549, 0.2706, 0.1255);
    vec3 purpleLight = bytes2.r * vec3(0.8824, 0.0, 1.0);
    vec3 greenLight = bytes2.b * vec3(0.0627, 0.5059, 0.1294);
    vec3 combinedLight = (orangeLight + blueLight + whiteLight + redLight + purpleLight + greenLight) ;
    
    // Add this to clamp brightness while preserving intensity (color ratios)
float maxBrightness = MAX_FLOODFILL_INTENSITY;  // Adjust this threshold as needed (e.g., 1.0 for full brightness cap)
float currentBrightness = length(combinedLight);
if (currentBrightness > maxBrightness) {
    combinedLight *= maxBrightness / currentBrightness;
}
  
    
    const vec3 defaultBlocklight = vec3(1.0, 0.8, 0.5843);
    const float VOXEL_FADE_START = VOXEL_RADIUS / 2;
    const float VOXEL_FADE_END = VOXEL_RADIUS;
    float dist = length(viewPos);
    float fade = smoothstep(VOXEL_FADE_START, VOXEL_FADE_END, dist);
    blocklight.rgb = mix(combinedLight, defaultBlocklight, fade);
   
    
   
    vec3 shadow = texture(shadowtex0, texcoord*100.).rgb;
		if(texcoord.x < .01 && texcoord.y < .01) color.rgb  = shadow;
}
else
{
  blocklight.rgb =  vec3(1.0, 0.8, 0.5843) ;
}
#else
blocklight.rgb =  vec3(1.0, 0.8, 0.5843) ;
#endif
    color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
}

  

