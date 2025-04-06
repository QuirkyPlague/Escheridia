#version 410 compatibility


#include "/lib/util.glsl"

//received vertex variables
in vec2 texcoord;
in vec4 glcolor;
in vec2 lmcoord;
in vec3 normal;
uniform sampler2D gtexture;

//cloud colors
vec4 cloudColor = vec4 (0.0);
vec4 dayCloudColor = vec4(1.0, 1.0, 1.0, 0.444);
vec4 earlyCloudColor = vec4(1.0, 0.6, 0.2941, 0.9);
vec4 nightCloudColor = vec4(0.9451, 0.9451, 0.9451, 0.9);
vec4 duskCloudColor = vec4(0.9294, 0.3294, 0.0941, 0.9);

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;

void main() 
{
	
    if(worldTime >= 0 && worldTime < 1000)
	  {
      float time = smoothstep(0, 1000, float(worldTime));
      cloudColor = mix(earlyCloudColor, dayCloudColor, time);
	  }
    else if(worldTime >= 1000 && worldTime < 11500)
     {
        float time = smoothstep(10000, 11500, float(worldTime));
        cloudColor = mix(dayCloudColor, duskCloudColor, time);
    }
    else if(worldTime >= 11500 && worldTime < 13000)
     {
        float time = smoothstep(11500, 13000, float(worldTime));
        cloudColor = mix(duskCloudColor, nightCloudColor, time);
    }
    else if(worldTime >= 13000 && worldTime < 24000)
     {
         float time = smoothstep(23215, 24000, float(worldTime));
        cloudColor = mix(nightCloudColor, earlyCloudColor, time);
    }
	
 
lightmapData = vec4(lmcoord, 0.0, 1.0);
encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);

  	color = texture(colortex0, texcoord) * glcolor * cloudColor;
color.rgb = pow(color.rgb, vec3(2.2));

}