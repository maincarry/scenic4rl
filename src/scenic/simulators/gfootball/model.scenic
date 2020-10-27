"""Scenic World Model for GFootball Scenarios."""

from scenic.simulators.gfootball.simulator import GFootBallSimulator

simulator GFootBallSimulator()

# Set up workspace
width = 2
length = 0.42*2
workspace = Workspace(RectangularRegion(0 @ 0, 0, width, length)) #ask eddie about first two parameters

#askEddie: How to define regions within workspace: Dbox, left half, right half, etc

# types of objects

class Ball:
    position: Point on workspace
    direction: Range(0, 360) deg
    width: 0.005
    length: 0.005


#AskEddie: How to modify distribution of position based on role?
class Player:
    position: Point on workspace
    direction: Range(0, 360) deg
    width: 0.01
    length: 0.01
    role: "CM"
    active: False
    ball_owned: False


#AskEddie: should we specify a boolean field in player? instead of My/Op Player

class MyPlayer(Player):
    pass

class OpPlayer(Player):
    pass
