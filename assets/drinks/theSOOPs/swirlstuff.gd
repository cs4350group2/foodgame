extends GPUParticles3D

func _ready():
	var mat = process_material as ParticleProcessMaterial
	mat.set_param_min(ParticleProcessMaterial.PARAM_SCALE, 0.002)
	mat.set_param_max(ParticleProcessMaterial.PARAM_SCALE, 0.005)
