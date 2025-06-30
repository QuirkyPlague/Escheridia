#ifndef POST_PROCESSING_GLSL
#define POST_PROCESSING_GLSL

uniform float contrast = CONTRAST;
uniform float saturation = SATURATION;
uniform float brightness = BRIGHTNESS;

/*
uniform float contrast   = 0.5;
uniform float saturation = 0.5;
uniform float brightness = 0.5;
*/


/*
** Contrast, saturation, brightness
** Code of this function is from TGM's shader pack
** http://irrlicht.sourceforge.net/phpBB2/viewtopic.php?t=21057
*/

// For all settings: 1.0 = 100% 0.5=50% 1.5 = 150%
vec3 CSB(vec3 color, float brt, float sat, float con)
{
	// Increase or decrease theese values to adjust r, g and b color channels seperately
	const float AvgLumR = 1.0;
	const float AvgLumG = 1.0;
	const float AvgLumB = 1.0;
	
	const vec3 LumCoeff = vec3(0.2125, 0.7154, 0.0721);
	
  

	vec3 AvgLumin  = vec3(AvgLumR, AvgLumG, AvgLumB);
	vec3 brtColor  = color * brt;
	vec3 intensity = vec3(dot(brtColor, LumCoeff));
	vec3 satColor  = mix(intensity, brtColor, sat);
	vec3 conColor  = mix(AvgLumin, satColor, con);
	
	return conColor;
}
#endif