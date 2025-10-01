class_name RPC
extends RefCounted

func serialize() -> String:
	return JSON.stringify(inst_to_dict(self))

# using untyped version see comments below
static func deserialize(json :String):
	var test_json_conv = JSON.new()
	test_json_conv.parse(json)
	var result: = test_json_conv.get_data()
	if not typeof(result.result) == TYPE_DICTIONARY:
		push_error("Can't deserialize JSON, error at line %d: %s \n json:%s" % [result.error_line, result.error_string, json])
		return null
	return dict_to_inst(result.result)

# this results in orpan node, for more details https://github.com/godotengine/godot/issues/50069
#func deserialize2(data :Dictionary) -> RPC:
#	return  dict2inst(data) as RPC
