extends Node


var started = false
var last_checkpoint = null

var current_level = 0

var current_level_stats = {
	"teleport_enemies": 0,
	"teleport": false
}

var levels = [
	{
		"enemies": 0,
		"objectives": "Find  and  enter  the  teleport,  avoid  radioactive  ponds,  don't  fall  of  the  platform.",
		"objective_conditions": {
			"teleport": true,
			"teleport_enemies": 0
		}
	},
	
	{
		"enemies": 1,
		"objectives": "Teleport  yourself,  don't  get  killed.",
		"objective_conditions": {
			"teleport": true,
			"teleport_enemies": 0
		}
	},
	
	{
		"enemies": 1,
		"objectives": "Teleport  the  robobull.",
		"objective_conditions": {
			"teleport": false,
			"teleport_enemies": 1
		}
	},
	
	{ 
		"enemies": 1,
		"objectives": "Teleport  the  robobull  then  yourself.",
		"objective_conditions": {
			"teleport": true,
			"teleport_enemies": 1
		}
	},
	
	{ 
		"enemies": 2,
		"objectives": "Teleport  at  least  one  robobull.",
		"objective_conditions": {
			"teleport": false,
			"teleport_enemies": 1
		}
	},
	
	{
		"enemies": 2,
		"objectives": "Teleport  two  robobulls.",
		"objective_conditions": {
			"teleport": false,
			"teleport_enemies": 2
		}
	},
	
	{
		"enemies": 3,
		"objectives": "Teleport  yourself,  don't  get  killed",
		"objective_conditions": {
			"teleport": true,
			"teleport_enemies": 0
		}
	},
	
	{
		"enemies": 3,
		"objectives": "Teleport  2  robobulls  and  yourself",
		"objective_conditions": {
			"teleport": true,
			"teleport_enemies": 2
		}
	},
	
	{
		"enemies": 4,
		"objectives": "Have fun, bring a souvenier!",
		"objective_conditions": {
			"teleport": true,
			"teleport_enemies": 1
		}
	},
	
	{
		"enemies": 8,
		"objectives": "I wish you luck!",
		"objective_conditions": {
			"teleport": true,
			"teleport_enemies": 0
		}
	}
]

func current_objectives():
	return levels[current_level]["objectives"]

func current_enemies():
	return levels[current_level]["enemies"]

func next_level():
	if (current_level + 1) < levels.size():
		current_level += 1
		return current_level
	else: 
		return false

func reset_stats():
	current_level_stats = {
		"teleport_enemies": 0,
		"teleport": false
	}
	
func robobul_teleported():
	current_level_stats["teleport_enemies"] += 1

func teleported():
	current_level_stats["teleport"] = true
	
func objectives_met():
	var objectives = levels[current_level]["objective_conditions"]
	return current_level_stats["teleport_enemies"] >= objectives["teleport_enemies"] and \
			(!objectives["teleport"] or (objectives["teleport"] and current_level_stats["teleport"]))
