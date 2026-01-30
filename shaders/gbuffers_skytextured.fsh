
#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;
in vec4 glcolor;
in vec3 viewDir;

uniform sampler2D gtexture;
uniform float sunAngle;

/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormal;

void main() {
    vec4 color = texture(gtexture, texcoord) * glcolor;
    float brightness = getLuminance(color.rgb);
    vec3 bloomColor = color.rgb * (1.0 + brightness * 2.0);

    float moonDim = smoothstep(-0.1,0.1, sunAngle);
    if (brightness < 0.5) {
        bloomColor *= (1.0 - moonDim * 0.7);
    }

    outColor = vec4(bloomColor, color.a);
    outNormal = vec4(0.5,0.5,1.0,1.0);
}