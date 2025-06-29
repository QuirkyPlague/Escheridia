#ifndef BLOOM_GLSL
#define BLOOM_GLSL 1 //[0 1]

#include "/lib/util.glsl"
#include "/lib/water/waterFog.glsl"

//Adapted from https://learnopengl.com/Guest-Articles/2022/Phys.-Based-Bloom and Glimmer Shaders https://github.com/jbritain/glimmer-shaders
vec3 powVec3(vec3 v, float p)
{
    return vec3(pow(v.x, p), pow(v.y, p), pow(v.z, p));
}

vec3 toSRGB(vec3 v) { return powVec3(v, 1.0/2.2); }

float RGBToLuminance(vec3 col)
{
    return dot(col, vec3(0.2126f, 0.7152f, 0.0722f));
}

float karisAverage(vec3 col)
{
    // Formula is 1 / (1 + luma)
    float luma = RGBToLuminance(toSRGB(col)) * 0.25f;
    return 1.0f / (1.0f + luma);
}

struct Bloom {
  vec2 origin;
  int mipLevel;
  float scale;
};
Bloom screen = Bloom(vec2(0.0), 1, 0.5); // 1/2 scale


Bloom screens[1] = Bloom[1](screen);

vec3 downsampleScreen(sampler2D srcTexture, vec2 texCoord)
{

     float x = 1.0 / float(viewWidth * BLOOM_QUALITY);
  float y = 1.0 / float(viewHeight * BLOOM_QUALITY);

    // Take 13 samples around current texel:
    // a - b - c
    // - j - k -
    // d - e - f
    // - l - m -
    // g - h - i
    // === ('e' is the current texel) ===
    vec3 a = texture(srcTexture, vec2(texCoord.x - 2*x, texCoord.y + 2*y)).rgb;
    vec3 b = texture(srcTexture, vec2(texCoord.x,       texCoord.y + 2*y)).rgb;
    vec3 c = texture(srcTexture, vec2(texCoord.x + 2*x, texCoord.y + 2*y)).rgb;

    vec3 d = texture(srcTexture, vec2(texCoord.x - 2*x, texCoord.y)).rgb;
    vec3 e = texture(srcTexture, vec2(texCoord.x,       texCoord.y)).rgb;
    vec3 f = texture(srcTexture, vec2(texCoord.x + 2*x, texCoord.y)).rgb;

    vec3 g = texture(srcTexture, vec2(texCoord.x - 2*x, texCoord.y - 2*y)).rgb;
    vec3 h = texture(srcTexture, vec2(texCoord.x,       texCoord.y - 2*y)).rgb;
    vec3 i = texture(srcTexture, vec2(texCoord.x + 2*x, texCoord.y - 2*y)).rgb;

    vec3 j = texture(srcTexture, vec2(texCoord.x - x, texCoord.y + y)).rgb;
    vec3 k = texture(srcTexture, vec2(texCoord.x + x, texCoord.y + y)).rgb;
    vec3 l = texture(srcTexture, vec2(texCoord.x - x, texCoord.y - y)).rgb;
    vec3 m = texture(srcTexture, vec2(texCoord.x + x, texCoord.y - y)).rgb;

    // Apply weighted distribution:
    // 0.5 + 0.125 + 0.125 + 0.125 + 0.125 = 1
    // a,b,d,e * 0.125
    // b,c,e,f * 0.125
    // d,e,g,h * 0.125
    // e,f,h,i * 0.125
    // j,k,l,m * 0.5
    // This shows 5 square areas that are being sampled. But some of them overlap,
    // so to have an energy preserving downsample we need to make some adjustments.
    // The weights are the distributed, so that the sum of j,k,l,m (e.g.)
    // contribute 0.5 to the final color output. The code below is written
    // to effectively yield this sum. We get:
    // 0.125*5 + 0.03125*4 + 0.0625*4 = 1
    vec3 dsample;
    
    vec3 group0 = (a+b+d+e) * (0.124/4.0);
    vec3 group1 = (b+c+e+f) * (0.124/4.0);
    vec3 group2 = (d+e+g+h) * (0.125/4.0);
    vec3 group3 = (e+f+h+i) * (0.125/4.0);
    vec3 group4 = (j+k+l+m) * (0.5/4.0);

    group0 *= karisAverage(group0);
    group1 *= karisAverage(group1);
    group2 *= karisAverage(group2);
    group3 *= karisAverage(group3);
    group4 *= karisAverage(group4);
    dsample = group0 + group1 + group2 + group3 + group4;
  
    return dsample;
}

vec3 upSample(sampler2D srcTexture,vec2 texCoord)
{
   float x = BLOOM_RADIUS / (viewWidth * BLOOM_QUALITY);
  float y = BLOOM_RADIUS / (viewHeight * BLOOM_QUALITY);

    // Take 9 samples around current texel:
    // a - b - c
    // d - e - f
    // g - h - i
    // === ('e' is the current texel) ===
    vec3 a = texture(srcTexture, vec2(texCoord.x - x, texCoord.y + y)).rgb;
    vec3 b = texture(srcTexture, vec2(texCoord.x,     texCoord.y + y)).rgb;
    vec3 c = texture(srcTexture, vec2(texCoord.x + x, texCoord.y + y)).rgb;

    vec3 d = texture(srcTexture, vec2(texCoord.x - x, texCoord.y)).rgb;
    vec3 e = texture(srcTexture, vec2(texCoord.x,     texCoord.y)).rgb;
    vec3 f = texture(srcTexture, vec2(texCoord.x + x, texCoord.y)).rgb;

    vec3 g = texture(srcTexture, vec2(texCoord.x - x, texCoord.y - y)).rgb;
    vec3 h = texture(srcTexture, vec2(texCoord.x,     texCoord.y - y)).rgb;
    vec3 i = texture(srcTexture, vec2(texCoord.x + x, texCoord.y - y)).rgb;

    vec3 upsample;
    // Apply weighted distribution, by using a 3x3 tent filter:
    //  1   | 1 2 1 |
    // -- * | 2 4 2 |
    // 16   | 1 2 1 |
    upsample = e*4.0;
    upsample += (b+d+f+h)*2.0;
    upsample += (a+c+g+i);
    upsample *= 1.0 / 16.0;
    return upsample;
}

// takes a texcoord within a bloom tile and scales it up to spread across the whole screen
vec2 scaleToBloomTile(vec2 coord, Bloom screen){
  return (coord - screen.origin) / screen.scale;
}

// takes a full screen texcoord and scales it down to map to a bloom tile
vec2 scaleFromBloomTile(vec2 coord, Bloom screen){
  return coord * screen.scale + screen.origin;
}

vec3 computeBloomMix(vec2 texcoord)
{
    float bloomStrength = 0.23;
   if(inWater)
   {
      bloomStrength = 0.73;
   }
	vec3 hdr = texture(colortex0, texcoord).rgb;
    vec3 blm = texture(colortex12, texcoord).rgb;
	float rain = texture(colortex9, texcoord).r;
    vec3 col = mix(hdr, blm, vec3(bloomStrength));
    return col;
}
#endif