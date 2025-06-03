#version 330 compatibility

uniform int renderStage;
uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;
in vec3 modelPos;
in vec3 viewPos;
in vec4 glcolor;

float fogify(float x, float w) {
	return w / (x * x + w);
}

vec3 calcSkyColor(vec3 pos) {
	float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	return mix(skyColor, fogColor, fogify(max(upDot, 0.0), 0.25));
}


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
if (renderStage == MC_RENDER_STAGE_STARS) {
		color = glcolor * 5.5;
	} else {
		vec3 pos = viewPos;
		color = vec4(calcSkyColor(normalize(pos)), 1.0);
	}
}
