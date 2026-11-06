shader_type canvas_item;
render_mode unshaded;

void fragment() {
    vec2 d = TEXTURE_PIXEL_SIZE * 4.0;
    float a = texture(TEXTURE, UV).a;
    a += texture(TEXTURE, UV + vec2(d.x, 0.0)).a;
    a += texture(TEXTURE, UV - vec2(d.x, 0.0)).a;
    a += texture(TEXTURE, UV + vec2(0.0, d.y)).a;
    a += texture(TEXTURE, UV - vec2(0.0, d.y)).a;
    a += texture(TEXTURE, UV + d).a;
    a += texture(TEXTURE, UV - d).a;
    a += texture(TEXTURE, UV + vec2(d.x, -d.y)).a;
    a += texture(TEXTURE, UV + vec2(-d.x, d.y)).a;
    COLOR = vec4(0.95, 0.01, 0.025, a / 9.0 * 0.55);
}
