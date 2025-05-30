#ifndef UTIL_GLSL
#define UTIL_GLSL

uniform mat4 gbufferProjection;
#include "/lib/uniforms.glsl"
#include "/lib/common.glsl"
#include "/lib/distort.glsl"
#include "/lib/postProcessing.glsl"
#include "/lib/blockIDs.glsl"

float getDepth(vec2 texcoord)
{
    float depth = texture(depthtex0, texcoord).r;
    return depth;
}
float getTranslucentDepth(vec2 texcoord)
{
    float depth = texture(depthtex1, texcoord).r;
    return depth;
}
float getOpaqueDepth(vec2 texcoord)
{
    float depth = texture(depthtex2, texcoord).r;
    return depth;
}
vec3 viewSpaceToScreenSpace(vec3 viewPosition) {
	vec3 screenPosition  = vec3(gbufferProjection[0].x, gbufferProjection[1].y, gbufferProjection[2].z) * viewPosition + gbufferProjection[3].xyz;
	     screenPosition /= -viewPosition.z;

	return screenPosition * 0.5 + 0.5;
}
float viewSpaceToScreenSpace(float depth, mat4 projection) {
	return ((projection[2].z * depth + projection[3].z) / -depth) * 0.5 + 0.5;
}

vec4 findShadowClipPos(vec3 feetPlayerPos)
{
  vec4 shadowViewPos = shadowModelView * vec4(feetPlayerPos, 1.0);
  vec4 shadowClipPos = shadowProjection * shadowViewPos;
  return shadowClipPos;
}


float DistributionGGX(vec3 N, vec3 H, float roughness)
{
    float a      = roughness*roughness;
    float a2     = a*a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;
	
    float num   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
	
    return num / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;
	
    return num / denom;
}
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);
	
    return ggx1 * ggx2;
}

vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
} 
float f0_to_ior(float f0) {
	float sqrt_f0 = sqrt(f0) * 0.99999;
	return (1.0 + sqrt_f0) / (1.0 - sqrt_f0);
}

vec3 fresnel_dielectric_n(float cos_theta, float n) {
	float g_sq = sqrt(n) + sqrt(cos_theta) - 1.0;

	if (g_sq < 0.0) return vec3(1.0); // Imaginary g => TIR

	float g = sqrt(g_sq);
	float a = g - cos_theta;
	float b = g + cos_theta;

	return vec3(0.5 * sqrt(a / b) * (1.0 + sqrt((b * cos_theta - 1.0) / (a * cos_theta + 1.0))));
}

vec3 fresnel_dielectric(float cos_theta, float f0) {
	float n = f0_to_ior(f0);
	return fresnel_dielectric_n(cos_theta, n);
}

//fetch noise tex
vec4 getNoise(vec2 coord)
{
  ivec2 screenCoord = ivec2(coord * vec2(viewWidth, viewHeight)); // exact pixel coordinate onscreen
  ivec2 noiseCoord = screenCoord % noiseTextureResolution; // wrap to range of noiseTextureResolution
  return texelFetch(noisetex, noiseCoord, 0);
}

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position)
 {
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

float IGN(vec2 coord)
{
    return fract(52.9829189f * fract(0.06711056f * coord.x + 0.00583715f* coord.y));
}

float IGN(vec2 coord, int frame)
{
    return  IGN(coord + 5.588238 * (frame & 63));
}

vec2 vogelDisc(int stepIndex, int stepCount, float noise) {
    float rotation = noise * 2 * PI;
    const float goldenAngle = 2.4;

    float r = sqrt(stepIndex + 0.5) / sqrt(float(stepCount));
    float theta = stepIndex * goldenAngle + rotation;

    return r * vec2(cos(theta), sin(theta));
}

float luminance(vec3 color)
{
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float HG(float g, float cosA)
{
    // Temporary hotfix for black plague problem
    // TODO: track down why vectors used to calculate cosA are not normalized (or contain NaNs)
    cosA = clamp(cosA, -1, 1);

     float g2 = g * g;
    return ((1.0 - g2) / pow(abs(1.0 + g2 - 2.0*g*cosA), 1.5));
}
float CS(float g, float costh)
{
    return (3.0 * (1.0 - g * g) * (1.0 + costh * costh)) / (4.0 * PI * 2.0 * (2.0 + g * g) * pow(1.0 + g * g - 2.0 * g * costh, 3.0/2.0));
}



vec3 screenSpaceToViewSpace(vec3 screenPosition, mat4 projectionInverse) {
	screenPosition = screenPosition * 2.0 - 1.0;

	vec3 viewPosition  = vec3(vec2(projectionInverse[0].x, projectionInverse[1].y) * screenPosition.xy + projectionInverse[3].xy, projectionInverse[3].z);

    viewPosition /= projectionInverse[2].w * screenPosition.z + projectionInverse[3].w;

	return viewPosition;
}

float screenSpaceToViewSpace(float depth, mat4 projectionInverse) {
	depth = depth * 2.0 - 1.0;
	return projectionInverse[3].z / (projectionInverse[2].w * depth + projectionInverse[3].w);
}

vec3 getShadowScreenPos(vec4 shadowClipPos){
	vec3 shadowScreenPos = distortShadowClipPos(shadowClipPos.xyz); //apply shadow distortion
  	shadowScreenPos.xyz = shadowScreenPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1


	return shadowScreenPos;
}

vec3 change_luminance(vec3 c_in, float l_out)
{
    float l_in = luminance(c_in);
    return c_in * (l_out / l_in);
}




#define _rcp(x) (1.0 / x)
float rcp(in float x) {
    return _rcp(x);
}
vec2 rcp(in vec2 x) {
    return _rcp(x);
}
vec3 rcp(in vec3 x) {
    return _rcp(x);
}
vec4 rcp(in vec4 x) {
    return _rcp(x);
}






#endif
