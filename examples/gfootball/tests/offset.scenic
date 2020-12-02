from scenic.simulators.gfootball.model import *
from scenic.simulators.gfootball.simulator import GFootBallSimulator

param game_duration = 400
param deterministic = False


ego = Ball at 0 @ 0
mygk = MyPlayer offset by 10 @ 10,
        with role "GK"

print(mygk.position)

