
#version 330 compatibility

in vec2 texcoord;
in vec4 glcolor;

uniform sampler2D gtexture;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec4 color = texture(gtexture, texcoord) * glcolor;
    
    if (color.a < 0.01) {
        discard;
    }
    
    outColor = color;
}
