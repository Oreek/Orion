
#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;
in vec4 glcolor;

uniform sampler2D gtexture;

/* RENDERTARGETS: 0,3 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outSpecular;

void main() {
    vec4 color = texture(gtexture, texcoord) * glcolor;
    
    if (color.a < 0.1) {
        discard;
    }
    
    color.rgb *= 3.0;
    
    outColor = vec4(color.rgb, 1.0);
    outSpecular = vec4(0.8, 0.0, 1.0, 1.0);
}
