#version $1
precision mediump float;
uniform sampler2D u_image;
uniform float u_alpha;
uniform bool u_show_blocks;
in vec2 v_tex_coord;
in vec4 v_color;
out vec4 o_color;
void main()
{
  if (u_show_blocks) {
    o_color = v_color;
    return;
  }

  // get the color from the attributes
  vec4 input_color = v_color;
  // set its alpha color if necessary
  if (input_color.w == 1.0)
  {
    input_color.w = u_alpha;
  }
  // get the color from the texture
  o_color = texture(u_image, v_tex_coord);
  // if it's black, make it a transparent pixel
  if (o_color.rgb == vec3(0.0, 0.0, 0.0))
  {
    o_color = vec4(0.0, 0.0, 0.0, 0.0);
  }
  // otherwise, use the input color
  else
  {
    o_color = input_color;
  }
  // discard transparent pixels
  if (o_color.w == 0.0)
  {
    discard;
  }
}
