from scenic.simulators.gfootball import rl_interface
from scenic.simulators.gfootball.rl_interface import GFScenicEnv

import os
cwd = os.getcwd()


tracedir = f"vids"
rewards = "scoring"#'scoring,checkpoints'

gf_env_settings = {
    "stacked": True,
    "rewards": rewards,
    "representation": 'extracted',
    "players": [f"agent:left_players=1"],
    "real_time": True,
    "action_set": "default",
    "dump_full_episodes": True,
    "dump_scores": True,
    "write_video": True,
    "tracesdir": tracedir,
    "write_full_episode_dumps": True,
    "write_goal_dumps": True,
    "render": True
}

#scenario_file = f"{cwd}/exp_0_5/academy_pass_and_shoot_with_keeper.scenic"
#scenario_file = f"../_scenarios/generic/rts/gen_0.scenic"
scenario_file = f"../_scenarios/generic/pass_n_shoot/gen_0.scenic"
from scenic.simulators.gfootball.utilities.scenic_helper import buildScenario
scenario = buildScenario(scenario_file)

env = GFScenicEnv(initial_scenario=scenario, gf_env_settings=gf_env_settings)


import gfootball

#env = gfootball.env.create_environment("academy_pass_and_shoot_with_keeper", number_of_left_players_agent_controls=1, render=False, representation="extracted",
#                                                   rewards=rewards, stacked=True, write_video=True, write_full_episode_dumps=True, logdir=tracedir)
rews =  []

for _ in range(100):
    env.reset()
    rew = 0
    #input("Press Any Key to Continue")
    done = False

    while not done:
        _,r,done,_ = env.step(env.action_space.sample())
        rew+=r

    rews.append(r)

import numpy as np
rews  = np.array(rews)
print("Mean, Count: ", np.mean(rews), rews.shape[0])