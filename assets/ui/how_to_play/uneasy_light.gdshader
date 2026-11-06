shader_type canvas_item;
render_mode unshaded;

void fragment() {
    vec4 art = texture(TEXTURE, UV);
    float breathing = 0.94 + 0.06 * sin(TIME * 0.8);
    float haze = 0.025 * sin(UV.x * 13.0 + UV.y * 6.0 + TIME * 0.25);
    art.rgb *= breathing;
    art.rgb += vec3(max(haze, 0.0), 0.0, 0.0);
    COLOR = art;
}
