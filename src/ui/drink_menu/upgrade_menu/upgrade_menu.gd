extends PanelContainer
class_name UpgradeMenu

signal purchased

const UPGRADE_ENTRY = preload("res://src/ui/drink_menu/upgrade_menu/UpgradeEntry.tscn")

@onready var upgrade_list: VBoxContainer = %VBoxContainer

var upgrades: Array[UpgradeEntry] = []

var _purchasing := false
var _blocked := false

func refresh(blocked: bool = false) -> void:
	_blocked = blocked

	if _purchasing:
		return

	for entry: UpgradeEntry in upgrades:
		upgrade_list.remove_child(entry)
		entry.queue_free()
	upgrades.clear()

	var run := RunManager.current_run
	if run == null:
		return

	for upgrade: Upgrade in run.upgrade_repo.available_upgrades.values():
		if not (upgrade is EarningUpgrade or upgrade is StatUpgrade):
			continue

		var entry := UPGRADE_ENTRY.instantiate() as UpgradeEntry
		entry.setup(upgrade)
		entry.buy_requested.connect(_purchase)

		var reason := ""

		if _blocked:
			reason = "Unavailable right now"
		elif not is_finite(upgrade.price) or upgrade.price < 0.0:
			reason = "Unavailable"
		elif run.coins < upgrade.price:
			reason = "Not enough coins"

		entry.set_availability(reason.is_empty(), reason)

		upgrade_list.add_child(entry)
		upgrades.append(entry)
	
func _purchase(upgrade_id: StringName) -> void:
	if _purchasing or _blocked or not is_visible_in_tree():
		return
	
	var run = RunManager.current_run
	if run == null or not is_instance_valid(RunManager.active_level):
		return
	if not run.upgrade_repo.available_upgrades.has(upgrade_id):
		refresh(_blocked)
		return
		
	var upgrade: Upgrade = run.upgrade_repo.available_upgrades[upgrade_id]
	if not (upgrade is EarningUpgrade or upgrade is StatUpgrade):
		return
	if not is_finite(upgrade.price) or upgrade.price < 0.0:
		return
	
	var upgrade_copy: Upgrade = upgrade.duplicate(true) as Upgrade
	
	_purchasing = true
	
	if not run.try_remove_coins(upgrade.price):
		_purchasing = false
		refresh(_blocked)
		return
	
	RunManager.add_upgrade(upgrade_copy)
	
	_purchasing = false
	refresh(_blocked)
	purchased.emit()
