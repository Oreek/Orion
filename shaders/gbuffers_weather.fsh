
#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;
in vec4 glcolor;

uniform sampler2D gtexture;
uniform float rainStrength;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec4 color = texture(gtexture, texcoord) * glcolor;

    color.a *= 0.5 + rainStrength * 0.3;

    color.rgb = mix(color.rgb, vec3(0.7,0.8,1.0), 0.2);

    if (color.a < 0.01) {
        discard;
    }

    outColor = color;
}