#version $1
uniform mat3 u_matrix;
uniform int u_char_counts[1000];
uniform int u_start_line;
uniform int u_start_column;
uniform float u_font_height;
in vec2 a_position;
in vec4 a_color;
in mat3 a_translate_matrix;
in mat3 a_texture_matrix;
in mat3 a_scale_matrix;
out vec2 v_tex_coord;
out vec4 v_color;
void main()
{
  int total_char_count = 0;
  int current_line = 0;
  for (int i=0; i<1000; ++i)
  {
    total_char_count += u_char_counts[i];
    if (total_char_count > gl_InstanceID)
    {
      total_char_count -= u_char_counts[i];
      break;
    }
    else
    {
      current_line += 1;
    }
  }
  mat3 translate_matrix = a_translate_matrix;
  translate_matrix[2][1] += u_font_height * float(u_start_line + current_line);
  int current_column = gl_InstanceID - total_char_count;
  if (u_start_column > current_column)
  {
    v_color = vec4(0.0, 0.0, 0.0, 0.0);
    return;
  }
  gl_Position = vec4((u_matrix * translate_matrix * a_scale_matrix * vec3(a_position, 1)).xy, 0, 1);
  v_tex_coord = (a_texture_matrix * vec3(a_position, 1)).xy;
  v_color = a_color;
}
