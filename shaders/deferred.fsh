#version 400 compatibility

#include "/lib/lighting/lighting.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/postProcessing.glsl"

in vec2 texcoord;
in vec3 normalF;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	//assign colortex buffers
	color = texture(colortex0, texcoord);
	vec3 albedo = color.rgb;
	vec2 lightmap = texture(colortex1, texcoord).rg;
	vec4 SpecMap = texture(colortex3, texcoord); 
  	vec3 encodedNormal = texture(colortex2, texcoord).rgb;
  	vec3 normal = normalize((encodedNormal - 0.5) * 2.0);
	vec3 surfNorm = texture(colortex4,texcoord).rgb;
	vec3 geoNormal = normalize((surfNorm - 0.5) * 2.0);
	float depth = texture(depthtex1, texcoord).r;
	if(depth ==1) return; //return out of function to prevent lighting interating with sky

	//space conversions
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  	vec3 worldPos = cameraPosition + feetPlayerPos;
  	vec3 viewDir = normalize(viewPos);
	vec3 V = normalize(cameraPosition - worldPos);
  	vec3 L = normalize(worldLightVector);
  	vec3 H = normalize(V + L);
	float VdotL = dot(normalize(feetPlayerPos), worldLightVector);

	bool isMetal = SpecMap.g >= 230.0 / 255.0;

	//PBR
	float roughness = pow(1.0 - SpecMap.r, 2.0);
	float sss = SpecMap.b;
	float emission = SpecMap.a;
  	vec3 emissive;
  	if (emission < 255.0/255.0) 
	{
    	emissive += color.rgb * (emission);
    	emissive += max(0.55 * pow(emissive, vec3(0.8)), 0.0);

    	emissive += min(luminance(emissive * 6.05) * pow(emissive, vec3(1.25)),33.15 ) ;
   		emissive = CSB(emissive, 1.0 , 0.55 , 1.0);
  	}
	
	vec3 shadow = getSoftShadow(feetPlayerPos, geoNormal, sss);
	vec3 f0;
  	if (isMetal) 
	{
   	 	
		f0 = vec3(SpecMap.g);
  	} 
  	else 
  	{
    	f0 = vec3(SpecMap.g);
  	}
	 float ao = encodedNormal.z * 0.5 + 0.5;

	color.rgb = getLighting(color.rgb, lightmap, normal, shadow, H, f0, roughness, V, ao, sss, VdotL, isMetal) + emissive;
}