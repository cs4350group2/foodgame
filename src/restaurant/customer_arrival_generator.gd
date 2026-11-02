extends RefCounted
class_name CustomerArrivalGenerator

func generate(config: ArrivalConfig, rules: Array[CustomerSpawnRule],
		rng: RandomNumberGenerator) -> Array[CustomerArrival]:
	var arrivals := _build_regular_schedule(config)
	if arrivals.is_empty():
		return []
	var eligible: Array[CustomerSpawnRule] = []
	for rule in rules:
		if rule != null and rule.selection_weight > 0.0:
			if rule.customer_type == &"" or rule.danger_rating <= 0:
				push_error("Special customer rules need a type and a positive danger rating.")
				return []
			eligible.append(rule)
	var pool := _choose_special_pool(config.danger_rating, arrivals.size(), eligible, rng)
	_assign_specials(arrivals, pool, config.wave_special_weight, rng)
	print("--- Customer schedule: %d customers, danger budget %d ---" % [arrivals.size(), config.danger_rating])
	for i in range(arrivals.size()):
		var arrival := arrivals[i]
		var customer_type := "Regular" if arrival.customer_type == &"" else String(arrival.customer_type)
		var group := "Gradual" if arrival.wave_index < 0 else "Wave %d" % (arrival.wave_index + 1)
		print("  %02d | %7.2fs | %-12s | %s" % [i + 1, arrival.arrival_time, customer_type, group])
	print("--- End customer schedule ---")
	return arrivals

func _build_regular_schedule(config: ArrivalConfig) -> Array[CustomerArrival]:
	var arrivals: Array[CustomerArrival] = []
	var section_count := config.wave_sizes.size()
	var gradual_per_section := floori(float(config.gradual_customer_count) / section_count)
	var extra_gradual := config.gradual_customer_count % section_count
	for wave in range(section_count):
		var gradual_count := gradual_per_section + (1 if wave < extra_gradual else 0)
		for i in range(gradual_count):
			arrivals.append(CustomerArrival.new())
		for i in range(config.wave_sizes[wave]):
			arrivals.append(CustomerArrival.new(&"", 0.0, wave))
	var wave_gaps := 0
	for size in config.wave_sizes:
		wave_gaps += size - 1
	var outside_gaps := arrivals.size() - 1 - wave_gaps
	var wave_duration := wave_gaps * config.wave_spawn_interval
	if config.total_time < wave_duration:
		push_error("Arrival duration is too short for the configured wave intervals.")
		return []
	var outside_interval := 0.0
	if outside_gaps > 0:
		outside_interval = (config.total_time - wave_duration) / outside_gaps
		if outside_interval <= 0.0:
			push_error("Arrival duration must leave time between gradual customers and waves.")
			return []
	var current := config.first_arrival_delay
	for i in range(arrivals.size()):
		if i > 0:
			var within_wave := arrivals[i].wave_index >= 0 \
				and arrivals[i].wave_index == arrivals[i - 1].wave_index
			current += config.wave_spawn_interval if within_wave else outside_interval
		arrivals[i].arrival_time = current
	return arrivals

func _choose_special_pool(budget: int, slots: int, rules: Array[CustomerSpawnRule],
		rng: RandomNumberGenerator) -> Array[StringName]:
	var pool: Array[StringName] = []
	if budget == 0 or slots <= 0 or rules.is_empty():
		return pool
	var highest_cost := 0
	for rule in rules:
		highest_cost = maxi(highest_cost, rule.danger_rating)
	# An excessive budget must not prevent the level from being generated.
	# Fill every slot using the normal selection weights, then stop.
	if budget > slots * highest_cost:
		for i in range(slots):
			pool.append(_choose_weighted_rule(rules, rng).customer_type)
		return pool
	# Find the smallest reachable total at or above the budget. Crossing the
	# budget needs at most one additional customer's cost, subject to slot capacity.
	var search_limit := mini(slots * highest_cost, budget + highest_cost - 1)
	var minimum_slots: Array[int] = []
	minimum_slots.resize(maxi(search_limit, 0) + 1)
	minimum_slots.fill(slots + 1)
	minimum_slots[0] = 0
	for danger in range(1, search_limit + 1):
		for rule in rules:
			if rule.danger_rating <= danger:
				minimum_slots[danger] = mini(minimum_slots[danger],
					minimum_slots[danger - rule.danger_rating] + 1)
	var target := budget
	while target <= search_limit and minimum_slots[target] > slots:
		target += 1
	if target > search_limit:
		push_error("Cannot reach danger budget %d with available customer types and %d slots." % [budget, slots])
		return pool
	var remaining := target
	while remaining > 0:
		var candidates: Array[CustomerSpawnRule] = []
		for rule in rules:
			if rule.danger_rating <= remaining \
					and minimum_slots[remaining - rule.danger_rating] <= slots - pool.size() - 1:
				candidates.append(rule)
		var chosen := _choose_weighted_rule(candidates, rng)
		pool.append(chosen.customer_type)
		remaining -= chosen.danger_rating
	return pool

func _choose_weighted_rule(rules: Array[CustomerSpawnRule],
		rng: RandomNumberGenerator) -> CustomerSpawnRule:
	var total_weight := 0.0
	for rule in rules:
		total_weight += rule.selection_weight
	var roll := rng.randf() * total_weight
	for rule in rules:
		roll -= rule.selection_weight
		if roll < 0.0:
			return rule
	return rules.back()

func _assign_specials(arrivals: Array[CustomerArrival], pool: Array[StringName],
		wave_weight: float, rng: RandomNumberGenerator) -> void:
	var available_slots: Array[int] = []
	for i in range(arrivals.size()):
		available_slots.append(i)
	for customer_type in pool:
		var total_weight := 0.0
		for index in available_slots:
			total_weight += wave_weight if arrivals[index].wave_index >= 0 else 1.0
		var roll := rng.randf() * total_weight
		var chosen_position := available_slots.size() - 1
		for position in range(available_slots.size()):
			var index := available_slots[position]
			roll -= wave_weight if arrivals[index].wave_index >= 0 else 1.0
			if roll < 0.0:
				chosen_position = position
				break
		arrivals[available_slots[chosen_position]].customer_type = customer_type
		available_slots.remove_at(chosen_position)
