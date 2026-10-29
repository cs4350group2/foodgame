// REEBOO Stylized VFX - solid particles (smoke, dust, poison clouds).
// Alpha blended: dark colors stay dark, so smoke can sit in front of fire.
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

#include "vfx_particle.gdshaderinc"
