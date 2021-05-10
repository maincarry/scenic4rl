"""Script allowing to play the game by multiple players."""

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function


from gfootball.env.scenario_builder import Scenario
from gfootball.env import config
from gfootball.env import football_env

import gfootball_engine as libgame
from gfootball.env import football_action_set

#AddPlayer(self, x, y, role, lazy=False, controllable=True):
num_my_player =  5
num_op_player =  5
num_total_controlled = num_my_player+num_op_player
settings = {

    "representation": 'extracted',
    "stacked": True,
    'action_set': "full",
    'dump_full_episodes': True,
    'real_time': True,
    'players': [f"agent:left_players={num_my_player},right_players={num_op_player}"],
    'level': '5_vs_5',
    'video_quality_level': 0,
    'physics_steps_per_frame': 10,
    'render_resolution_x': 1280,
}

cfg = config.Config(settings)


env = football_env.FootballEnv(cfg)

desig = -1
def print_obs(obs_list):


    global desig
    """
    for i, obs in enumerate(obs_list):
        #print(obs["active"], obs["designated"])

        
        if desig != obs["designated"]:
            print(obs["active"], obs["designated"])
            print("DESIG CHANGED!!!!!!!!!!!!!!!!!!!!!!!!!!")

            desig = obs["designated"]
        
    """
    

    #print()

env.render()
env.reset()
obs, rew, done, info = env.step([0] * num_total_controlled)
print_obs(obs)

#print(obs["active"], obs["designated"])
while True:
    obs, res, done, info = env.step([football_action_set.action_shot] * num_total_controlled)
    print("step")
    print_obs(obs)
    #_, _, done, _ = env.step([])
    if done:
        break


"""
try:
    while True:
        _, _, done, _ = env.step([])
        if done:
            env.reset()
except KeyboardInterrupt:
    logging.warning('Game stopped, writing dump...')
    env.write_dump('shutdown')
    exit(1)
    
"""
