
#version 330 compatibility

#include "/lib/settings.glsl"

in vec2 texcoord;
in vec4 glcolor;
in vec3 worldPos;

uniform sampler2D gtexture;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec4 color = texture(gtexture, texcoord) * glcolor;

    if (color.a < 0.1) {
        discard;
    }

    outColor = color;
}