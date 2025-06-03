#ifndef SKY_COLOR_GLSL
#define SKY_COLOR_GLSL

#include "/lib/uniforms.glsl"

uniform vec3 fogColor;
uniform vec3 skyColor;

float fogify(float x, float w) {
	return w / (x * x + w);
}

vec3 calcSkyColor(vec3 pos) {
	float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	return mix(skyColor, fogColor, fogify(max(upDot, 0.0), 0.25));
}

vec3 applySky(vec3 color, vec2 texcoord, float depth)
{
        vec3 viewPos = screenToView(texcoord, depth);
        vec3 normalViewPos = normalize(viewPos.xyz);
		color = vec3(calcSkyColor(normalize(normalViewPos)));
        return color;
}

#endif //SKY_COLOR_GLSL