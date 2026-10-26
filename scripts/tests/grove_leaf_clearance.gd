extends SceneTree

func _init() -> void: call_deferred("run")

func run() -> void:
	var stage=load("res://scripts/ui/grove_stage.gd").new()
	var tree_image: Image=stage.TREES.get_image()
	var leaf_image: Image=stage.GOLD_LEAVES.get_image()
	var failures: Array[String]=[]
	var tested:=0
	for tree_index in 6:
		for leaf_index in 3:
			for side in [200.0,216.0,224.0]:
				var rect: Rect2=stage.gold_leaf_rect(tree_index,leaf_index,side,0)
				var breaches:=0
				for y in range(256):
					for x in range(256):
						if leaf_image.get_pixel((leaf_index%2)*256+x,y).a<.01: continue
						var local:=rect.position+Vector2(x+.5,y+.5)*rect.size/256.0
						var source: Vector2=(local+Vector2(side*.5,0))*512.0/side
						for offset in [Vector2.ZERO,Vector2(-6,0),Vector2(6,0),Vector2(0,-6),Vector2(0,6),Vector2(-4,-4),Vector2(4,-4),Vector2(-4,4),Vector2(4,4)]:
							var pixel: Vector2i=Vector2i((source+offset).floor())
							if pixel.x<0 or pixel.y<0 or pixel.x>=512 or pixel.y>=512:
								breaches+=1
								continue
							var color: Color=tree_image.get_pixel((tree_index%3)*512+pixel.x,(tree_index/3)*512+pixel.y)
							if color.a<.98 or maxf(color.r,maxf(color.g,color.b))<.16: breaches+=1
				if breaches>0: failures.append("Tree %s leaf %s at side %s: %s unsafe samples"%[tree_index,leaf_index,side,breaches])
				tested+=1
	stage.free()
	print("GROVE_LEAF_CLEARANCE placements=",tested," failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
