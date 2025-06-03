#version 330 compatibility

out vec4 glcolor;
out vec3 modelPos;
out vec3 viewPos;

void main() {
	gl_Position = ftransform();
	glcolor = gl_Color;

	modelPos = gl_Vertex.xyz;
	viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;

}
