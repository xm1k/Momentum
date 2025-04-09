shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.5, 0.0, 1.0); // Цвет свечения
uniform float glow_power : hint_range(0, 5) = 1.0; // Сила свечения

void fragment() {
    // Берем цвет текстуры из текущего кадра анимации
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Свечение будет там, где альфа > 0
    float glow_mask = tex_color.a;
    
    // Основной цвет + свечение
    COLOR = tex_color + glow_color * glow_mask * glow_power;
}