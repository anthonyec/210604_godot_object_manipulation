extends Node

export var enabled: bool = true
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

func _clone_inbetween(from: Spatial, to: Spatial, percent: float, pos: Vector3): # TODO: Tidy up
	var duplicated_node: Spatial = from.duplicate()
	var translate_difference = to.global_transform.origin - from.global_transform.origin
	var rotation_difference = to.rotation - from.rotation
	var new_direction = _rotate_vector_by_quaternion(translate_difference, Quat(rotation_difference))
	var halfway_between_from_and_to = from.transform.interpolate_with(to.transform, percent).origin
		
	duplicated_node.name += '_clone_' + String(clone_count)
	clone_count += 1
	
#	duplicated_node.global_transform.origin = halfway_between_from_and_to
	duplicated_node.global_transform.origin = pos
	duplicated_node.rotation = rotation_difference * percent

	self.add_child(duplicated_node);
	
# https://docs.godotengine.org/en/stable/tutorials/math/beziers_and_curves.html
func _quadratic_bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: float):
		var q0 = p0.linear_interpolate(p1, t)
		var q1 = p1.linear_interpolate(p2, t)
		var r = q0.linear_interpolate(q1, t)
		
		return r
		
func _clone_inbetween_recursive(from: Spatial, to: Spatial, times: float):
	var gap = (1 / times)
	var middle = from.global_transform.origin.linear_interpolate(to.global_transform.origin, 0.5)
	var difference_direction = to.global_transform.origin.direction_to(from.global_transform.origin)
#	var direction_rotated = _rotate_vector_by_quaternion(difference_direction, Quat(to.rotation))
	var direction_rotated = to.global_transform.basis.z + Vector3(0, -0.28, 0.18)
	var plane = Plane(-difference_direction, Vector3.ZERO.distance_to(middle))
	var intersection = plane.intersects_ray(to.global_transform.origin, direction_rotated);
	
	DebugDraw.draw_ray_3d(Vector3.ZERO, -difference_direction, Vector3.ZERO.distance_to(middle), Color.white)
	DebugDraw.draw_box(Vector3.ZERO, Vector3(0.5, 0.5, 0.5), Color.white)
	
	if intersection:
		DebugDraw.draw_box(intersection, Vector3(1, 1, 1), Color.red)
	
	DebugDraw.draw_box(middle, Vector3(0.2, 0.2, 0.2), Color.blue)
	DebugDraw.draw_ray_3d(to.global_transform.origin, direction_rotated, 50, Color.aqua)
	DebugDraw.draw_ray_3d(
		middle,
		difference_direction,
		5,
		Color.green
	)
	
	for i in times:
		var q = _quadratic_bezier(from.global_transform.origin, intersection, to.global_transform.origin, i * gap)
		_clone_inbetween(from, to, i * gap, q)
		DebugDraw.draw_box(q, Vector3(0.2, 0.2, 0.2), Color.red)
	
func _ready():
	var orginal_node: Spatial = get_node(original)
	var clone_node: Spatial = get_node(clone)
	
#	_clone_inbetween_recursive(orginal_node, clone_node, 10);
	
	pass

func _process(delta):
	if !enabled:
		return
		
	if self.get_children().size() > 0:
		for child in self.get_children():
			self.remove_child(child)

	var orginal_node: Spatial = get_node(original)
	var clone_node: Spatial = get_node(clone)

	_clone_inbetween_recursive(orginal_node, clone_node, 6);
	pass
