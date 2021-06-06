extends Node

export var original: NodePath
export var clone: NodePath

var clone_count: int = 0

# https://gamedev.stackexchange.com/a/50545
func _rotate_vector_by_quaternion(v: Vector3, q: Quat):
	# Extract the vector part of the quaternion
	var u: Vector3 = Vector3(q.x, q.y, q.z)

	# Extract the scalar part of the quaternion
	var s: float = q.w

	# Do the math
	var vprime: Vector3 = 2 * u.dot(v) * u + (s*s - u.dot(u)) * v + 2 * s * u.cross(v);

	return vprime

func _clone(from: Spatial, to: Spatial):
	var duplicated_node: Spatial = from.duplicate()
	var translate_difference = to.global_transform.origin - from.global_transform.origin
	var rotation_difference = to.rotation - from.rotation
	
	# TODO: Is there an easier way to do this? I understand on a high-level why 
	# this was needed but I don't understand the actual maths behind it.
	var new_direction = _rotate_vector_by_quaternion(translate_difference, Quat(rotation_difference))
	
	DebugDraw.draw_ray_3d(
		from.global_transform.origin,
		new_direction.normalized(),
		new_direction.length(), 
		Color.red
	);
		
	duplicated_node.name += '_clone_' + String(clone_count)
	clone_count += 1
	
	duplicated_node.global_transform.origin = to.global_transform.origin + new_direction
	duplicated_node.rotation = to.rotation + rotation_difference
	
	self.add_child(duplicated_node);
	
	return [duplicated_node, to];

func _clone_recursive(from: Spatial, to: Spatial, times: int):
	var current_from: Spatial = from
	var current_to: Spatial = to
	
	for i in times:
		var clone = self._clone(current_from, current_to)
		current_from = clone[1]
		current_to = clone[0]
	
	pass	

func _ready():
	var orginal_node: Spatial = get_node(original)
	var clone_node: Spatial = get_node(clone)
	
	_clone_recursive(orginal_node, clone_node, 10);
	
	pass

func _process(delta):
	if false:
		return
		
	if self.get_children().size() > 0:
		for child in self.get_children():
			self.remove_child(child)

	var orginal_node: Spatial = get_node(original)
	var clone_node: Spatial = get_node(clone)

	_clone_recursive(orginal_node, clone_node, 20);
	pass
