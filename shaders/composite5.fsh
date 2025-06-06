#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/blockID.glsl"
#include "/lib/atmosphere/godrays.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/SSR.glsl" 

in vec2 texcoord;
vec4 waterMask=texture(colortex4,texcoord);
vec4 translucentMask=texture(colortex7,texcoord);
int blockID=int(waterMask)+100;
int blockID2=int(translucentMask)+102;
bool isWater=blockID==WATER_ID;
bool isTranslucent=blockID2==TRANSLUCENT_ID;
vec4 SpecMap = texture(colortex5, texcoord);

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

	
	
	float depth = texture(depthtex0, texcoord).r;
	
	vec2 lightmap = texture(colortex1, texcoord).rg; // we only need the r and g components
	vec3 encodedNormal = texture(colortex2, texcoord).rgb;
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
	normal=mat3(gbufferModelView)*normal;

	vec3 NDCPos=vec3(texcoord.xy,depth)*2.-1.;
 	vec3 viewPos=projectAndDivide(gbufferProjectionInverse,NDCPos);
  	vec3 viewDir=normalize(viewPos);

	vec3 reflectedDir = reflect(viewDir, normal);
    vec3 reflectedPos = vec3(0.0);
    vec3 reflectedColor = vec3(0.0);

	//reflectedDir.xy = clamp(reflectedDir.xy, vec2(-1.5), vec2(1.5));
	vec3 V=normalize((-viewDir));
	vec3  f0;
	if(SpecMap.g <= 229.0/255.0)
  	{
    	f0 = vec3(SpecMap.g);
  	}
  	else if(isWater)
  	{
    	f0 = vec3(0.02);
  	}
	else
	{
		f0 = color.rgb;
	}
    vec3 F=fresnelSchlick(max(dot(normal,V),0.),f0);
	
	bool reflectionHit = true;
	
	float jitter = IGN(gl_FragCoord.xy, frameCounter);
	reflectionHit && raytrace(viewPos, reflectedDir,8, jitter, reflectedPos);
	 
	 if(reflectionHit)
	 {
		#if DO_SSR == 1
		reflectedColor = texture(colortex0, reflectedPos.xy).rgb;
			 if(clamp(reflectedPos.xy, 0.0, 1.0) != reflectedPos.xy)
		{

				reflectedColor=calcSkyColor((reflect(viewDir,normal)));
				reflectedColor = mix(color.rgb, lightmap.g * reflectedColor * 0.5, F);
		}
		#else
				reflectedColor=calcSkyColor((reflect(viewDir,normal)));
				reflectedColor = mix(color.rgb, lightmap.g * reflectedColor * 0.5, F);
		
		#endif
	 }
		
	
	if(isWater || SpecMap.r >= 165.0/255.0)
	{
		color.rgb = mix(color.rgb, reflectedColor, F);
	}
	
}