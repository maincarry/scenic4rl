# Traffic Scenario 10: Crossing negotiation at an unsignalized intersection
# Definition: Ego-vehicle needs to negotiate with other vehicles to cross an unsignalized intersection. In this situation it is assumed that the first to enter the intersection has priority. 
# actor arrives at 4 way intersection before ego, has right of way. crosses intersection before ego.

import lgsvl
from scenic.core.distributions import TruncatedNormal
import scenic.simulators.lgsvl.actions as actions
from scenic.simulators.lgsvl.simulator import LGSVLSimulator
from scenic.simulators.lgsvl.map import setMapPath
setMapPath(__file__, 'maps/borregasave.xodr')
from scenic.simulators.lgsvl.model import *
import scenic.simulators.domains.driving.roads as roads

simulator = LGSVLSimulator('BorregasAve')
param time_step = 1.0/10

# CONSTANTS
fourLane = []
for i in network.intersections:
	if (len(i.incomingLanes) >= 8):
		fourLane.append(i)

intersection = Uniform(*fourLane) # ensure that it has a conflicting behavior, starts from conflicting lane. reformat?
index1 = Uniform(0, 1, 2, 3)
index2 = Uniform(0, 1, 2, 3)
require index1 != index2

egoAtStop = False


# GEOMETRY
lane1 = intersection.incomingLanes[index1]
lane2 = intersection.incomingLanes[index2]


pos1 = (OrientedPoint at lane1.centerline[-1]) offset by (-2, 2) @ 0 
pos2 = (OrientedPoint at lane2.centerline[-1]) offset by (-2, 2) @ 0

egoDist = TruncatedNormal(8, 2, 3, 10) # mean, stddev, low, high
actorDist = TruncatedNormal(5, 1, 1, 8) # start ego and actor at similar distances from intersection. actor closer.


# BEHAVIOR

behavior egoBehavior():
	gain = 0.1
	throttleStrength = (0.8, 1)
	for i in lane1.maneuvers:
		if i.type == roads.ManeuverType.STRAIGHT: 
			egoManeuver = i
			break
	turn = egoManeuver		
	while True:
		delta = self.heading relative to turn.connectingLane.centerline.orientation 
		take actions.SetSteerAction(-gain * delta)
		take actions.SetBrakeAction(0)
		take actions.SetThrottleAction(throttleStrength)

behavior actorCarBehavior(egoAtStop):
	turn = Uniform(*lane2.maneuvers) # not necessarily conflicting
	throttleStrength = (0, 1)
	speedup = (0, 1)
	smallDistance = (2, 5)
	while egoAtStop == False:

		# if close to intersection, stop quickly (actor must stop first)
		if ((distance from actorCar to intersection) <= smallDistance):
			take actions.SetThrottleAction(0.0)
			take actions.SetBrakeAction(1)

			# if ego is stopped, actor will go
			if ((distance from ego to intersection) <= smallDistance):
				egoAtStop = True
				
			else: # wait for ego to stop
				take actions.SetThrottleAction(0.0)
				take actions.SetBrakeAction(1)
	   
		else: # drive to intersction
			take actions.SetSpeedAction(ego.speed + speedup) #actor is faster than ego
			take actions.SetBrakeAction(0)
	
	randomBehavior = Uniform(*PossibleBehaviors)
	print("randomBeh:", randomBehavior)
	while egoAtStop:
		randomBehavior()

behavior chickenBehavior():
	for i in lane1.maneuvers:
		if i.type == roads.ManeuverType.STRAIGHT: 
			egoManeuver = i
			break
			
	#turn = Uniform(*egoManeuver.conflictingManeuvers) # make sure the actor can do them
	turnList = []
	for i in egoManeuver.conflictingManeuvers:
		if i.startLane == lane2:
			turnList.append(i)
	require len(turnList) >= 1
	turn = Uniform(*turnList)

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

behavior neverMoveBehavior():
	while True:
		take actions.SetThrottleAction(0.0)
		take actions.SetBrakeAction(1)

behavior conflictingStopBehavior():
	gain = 0.1
	# actor begins doing its turn, but then stops in the intersection
	for i in lane1.maneuvers:
		if i.type == roads.ManeuverType.STRAIGHT: 
			egoManeuver = i
			break
			
	turn = Uniform(*egoManeuver.conflictingManeuvers)
	throttleStrength = (0.5, 1)
	startPoint = actorCar.position
	randomDist = (3, 8)
	while ((distance from actorCar to startPoint) <= randomDist):
		delta = self.heading relative to turn.connectingLane.centerline.orientation
		take actions.SetReverseAction(False)
		take actions.SetSteerAction(-gain * delta)
		take actions.SetBrakeAction(0)
		take actions.SetThrottleAction(throttleStrength)

behavior turnBehavior():
	gain = 0.1
	turn = Uniform(*lane2.maneuvers)
	throttleStrength = (0, 1)
	speedup = (0, 1)
	startTurn = False

	while (startTurn == False):
		if(actorCar in intersection): 
			startTurn = True
		else:
			delta = self.heading relative to (roadDirection at lane2.centerline[-1])
			take actions.SetSteerAction(-gain * delta)
			
			# take actions.FollowLaneAction()
			take actions.SetReverseAction(False)
			take actions.SetBrakeAction(0)
			take actions.SetThrottleAction(throttleStrength)
	while startTurn:
		delta = self.heading relative to turn.connectingLane.centerline.orientation # do I need to do something with connections?
		take actions.SetSteerAction(-gain * delta)
		take actions.SetBrakeAction(0)
		take actions.SetThrottleAction(throttleStrength)

#PossibleBehaviors = [neverMoveBehavior, turnBehavior, conflictingStopBehavior, chickenBehavior]
PossibleBehaviors = [chickenBehavior]

# PLACEMENT
ego = EgoCar following roadDirection from pos1 by -egoDist,
	with behavior egoBehavior

actorCar = EgoCar following roadDirection from pos2 by -actorDist,
	with behavior actorCarBehavior(egoAtStop)
