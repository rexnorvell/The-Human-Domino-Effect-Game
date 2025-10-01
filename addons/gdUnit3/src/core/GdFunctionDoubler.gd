class_name GdFunctionDoubler
extends RefCounted

const DEFAULT_TYPED_RETURN_VALUES := {
	TYPE_NIL: "null",
	TYPE_BOOL: "false",
	TYPE_INT: "0",
	TYPE_FLOAT: "0.0",
	TYPE_STRING: "\"\"",
	TYPE_VECTOR2: "Vector2.ZERO",
	TYPE_RECT2: "Rect2()",
	TYPE_VECTOR3: "Vector3.ZERO",
	TYPE_TRANSFORM2D: "Transform2D()",
	TYPE_PLANE: "Plane()",
	TYPE_QUATERNION: "Quaternion()",
	TYPE_AABB: "AABB()",
	TYPE_BASIS: "Basis()",
	TYPE_TRANSFORM3D: "Transform3D()",
	TYPE_COLOR: "Color()",
	TYPE_NODE_PATH: "NodePath()",
	TYPE_RID: "RID()",
	TYPE_OBJECT: "null",
	TYPE_DICTIONARY: "Dictionary()",
	TYPE_ARRAY: "Array()",
	TYPE_PACKED_BYTE_ARRAY: "PackedByteArray()",
	TYPE_PACKED_INT32_ARRAY: "PackedInt32Array()",
	TYPE_PACKED_FLOAT32_ARRAY: "PackedFloat32Array()",
	TYPE_PACKED_STRING_ARRAY: "PackedStringArray()",
	TYPE_PACKED_VECTOR2_ARRAY: "PackedVector2Array()",
	TYPE_PACKED_VECTOR3_ARRAY: "PackedVector3Array()",
	TYPE_PACKED_COLOR_ARRAY: "PackedColorArray()",
}

static func return_value(type :int) -> String:
	if DEFAULT_TYPED_RETURN_VALUES.has(type):
		return DEFAULT_TYPED_RETURN_VALUES.get(type)
	return "void"

func double(func_descriptor :GdFunctionDescriptor) -> PackedStringArray:
	push_error("FunctionDoubler#double() is not implemented!")
	return PackedStringArray()

func extract_arg_names(argument_signatures :Array) -> PackedStringArray:
	var arg_names := PackedStringArray()
	for arg in argument_signatures:
		arg_names.append(arg._name)
	return arg_names

static func extract_constructor_args(args :Array) -> PackedStringArray:
	var constructor_args := PackedStringArray()
	for arg in args:
		var a := arg as GdFunctionArgument
		var arg_name := a._name
		var default_value = get_default(a)
		constructor_args.append(arg_name + "=" + default_value)
	return constructor_args

static func get_default(arg :GdFunctionArgument):
	if arg.default() != GdFunctionArgument.UNDEFINED:
		return arg.default()
	else:
		var arg_type := GdObjects.string_to_type(arg._type)
		return return_value(arg_type)
