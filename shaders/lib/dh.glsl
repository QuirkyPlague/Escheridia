#ifndef DH_GLSL
#define DH_GLSL

#ifdef DISTANT_HORIZONS

void dh_conversions(inout float depth, inout vec3 viewPos, vec2 texcoord, bool opaque)
{
if(opaque)
{
    depth = texture(dhDepthTex1, texcoord).r;
}
else
{
    depth = texture(dhDepthTex0, texcoord).r;
}

vec3 screenPos = vec3(texcoord, depth);

  screenPos *= 2.0;
  screenPos -= 1.0; // ndcPos
  vec4 homPos = dhProjectionInverse * vec4(screenPos, 1.0);
  viewPos = homPos.xyz / homPos.w;
}
#else
void dh_conversions(inout float depth, inout vec3 viewPos, vec2 texcoord, bool opaque)
{
    return;
}
#endif

#endif 