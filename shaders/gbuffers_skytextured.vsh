
#version 330 compatibility

out vec2 texcoord;
out vec4 glcolor;
out vec3 viewDir;

uniform mat4 gbufferModelViewInverse;

void main() {
    gl_Position = ftransform();

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    viewDir = (gbufferModelViewInverse * viewPos).xyz;
}