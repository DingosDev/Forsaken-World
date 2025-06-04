extends Node
class_name State

var state_machine = null
var host = null

func enter(_parameters=[]): pass

func step(_delta): pass

func conditions(): pass

func exit(): pass

func anim_finished(_anim_name): pass
