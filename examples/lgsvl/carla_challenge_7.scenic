# Traffic Scenario 07: Crossing traffic running a red light at an intersection
# Definition: Ego-vehicle is going straight at an intersection but a crossing vehicle runs a red light, forcing the ego-vehicle to perform a collision avoidance maneuver. 

from scenic.simulators.domains.driving.roads import *
from scenic.core.distributions import TruncatedNormal
import scenic.simulators.carla.actions as actions
from scenic.simulators.domains.driving.network import loadLocalNetwork
loadLocalNetwork(__file__, '../OpenDrive/Town05.xodr')
from scenic.simulators.carla.model import *
simulator = CarlaSimulator('Town05')



# CONSTANTS
index1 = Uniform(0, 1, 2, 3)
index2 = Uniform(0, 1, 2, 3)
require index1 != index2


# GEOMETRY
fourLane = []
for i in network.intersections:
	if (len(i.incomingLanes) >= 8):
		fourLane.append(i)

intersection = Uniform(*fourLane)

lane1 = intersection.incomingLanes[index1]
lane2 = intersection.incomingLanes[index2]

pos1 = (OrientedPoint at lane1.centerline[-1]) offset by (-2, 2) @ 0 # at last stretch of centerline, off center by at most 2
pos2 = (OrientedPoint at lane2.centerline[-1]) offset by (-2, 2) @ 0
	

# BEHAVIORS
behavior actorCarBehavior():
	print("ego's position: ", lane1.uid)
	for i in lane1.maneuvers:
		if i.type == ManeuverType.STRAIGHT: 
			egoManeuver = i
			break

	turn = Uniform(*egoManeuver.conflictingManeuvers)
	throttleStrength = (0.7, 1)
	gain = 0.1
	print("turn", turn)
	take actions.SetManualFirstGearShiftAction()
	take actions.SetManualGearShiftAction(False)
	breakpoint()
	while ((actorCar in intersection) == False):
	
		print("in first part")
		delta = self.heading relative to (roadDirection at lane2.centerline[-1])
		take actions.SetSteerAction(-gain * delta)
		
		# take actions.FollowLaneAction()
		take actions.SetReverseAction(False)
		take actions.SetBrakeAction(0)
		take actions.SetThrottleAction(throttleStrength)

	print("in second part")
	while (actorCar in intersection):
		# actor starts when ego starts, stops when ego stops.
		if (ego.speed > 0):
			delta = self.heading relative to turn.connectingLane.centerline.orientation
			take actions.SetReverseAction(False)
			take actions.SetSteerAction(-gain * delta)
			take actions.SetBrakeAction(0)
			take actions.SetThrottleAction(throttleStrength)

		else:
			take actions.SetThrottleAction(0.0)
			take actions.SetBrakeAction(1)

behavior egoBehavior():
	while True:
		take actions.SetThrottleAction(0.4) # hard coded for testing


# PLACEMENT
ego = Car following roadDirection from pos1 by (-5, -3), # behind the position by at most 5
	with speed 3,
	with behavior egoBehavior

actorCar = Car following roadDirection from pos2 by (-5, -3),
	with behavior actorCarBehavior,
	with speed 4



# old pseudocode -
# intersection = Uniform(*network.intersections)
# require (len(intersection.incomingLanes) == 4) # requires 4-way intersection
# lane1 = Uniform(*intersection.incomingLanes)
# lane2 = Uniform(*intersection.incomingLanes) 
# require (lane1 is not lane2)

# traffic lights not implemented, but if they were: red light across from actor, green across from ego.


# NOTES

# actor car sometimes in a position where there's no conflicting moves. make sure actor isn't in adjacent lane. 
# actor has brake on sometimes ?
