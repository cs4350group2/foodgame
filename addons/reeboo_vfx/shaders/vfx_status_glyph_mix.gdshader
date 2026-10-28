// REEBOO Stylized VFX - Status Effects: solid, outlined icon particles (alpha blended, readable on bright scenes).
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

#define STATUS_GLYPH_SOLID
#include "vfx_status_glyph.gdshaderinc"
