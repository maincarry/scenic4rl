from scenic.simulators.gfootball.model import *
from scenic.simulators.gfootball.simulator import GFootBallSimulator

param game_duration = 200
param deterministic = False
param offsides = False
param end_episode_on_score = True
param end_episode_on_out_of_play = True
param end_episode_on_possession_change = True


ego = Ball at 75 @ 3

MyGK at -99 @ 0
MyCB at 75 @ 5
MyCB at 70 @ 30

OpGK at 99 @ 0
OpCB at 75 @ 10

#player 1 past the defender