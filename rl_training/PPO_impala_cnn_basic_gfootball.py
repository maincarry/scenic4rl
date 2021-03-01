import socket
import gym
from stable_baselines3.common.evaluation import evaluate_policy
from stable_baselines3 import PPO
from stable_baselines3.common.monitor import Monitor
import os
import datetime
from stable_baselines3.common.callbacks import BaseCallback
from stable_baselines3.common.callbacks import EvalCallback
from stable_baselines3.common.preprocessing import is_image_space
from stable_baselines3.common.torch_layers import BaseFeaturesExtractor
from torch import nn
import torch as th
import gfootball

from rl_training.gfootball_impala_cnn import GfootballImpalaCNN


class PPO_GF_Impala:

    def __init__(self, level="academy_empty_goal_close"):

        self.scenario = level

        gf_env_settings = {
            "stacked": True,
            "rewards": 'scoring,checkpoints',
            "representation": 'extracted',
            "players": [f"agent:left_players=1"],
            "real_time": False,
            "action_set": "default"
        }

        self.rl_env = gfootball.env.create_environment(level, number_of_left_players_agent_controls=1, render=False, representation="extracted",
                                                       rewards='scoring,checkpoints')
        self.rl_env.eval_env = self.rl_env


    def train(self):
        ALGO = PPO
        n_eval_episodes = 10
        total_training_timesteps = 500000
        eval_freq = 10000

        save_dir = "./saved_models"
        logdir = "./tboard"

        os.makedirs(save_dir, exist_ok=True)
        os.makedirs(logdir, exist_ok=True)

        env = self.rl_env
        env = Monitor(env)

        policy_kwargs = dict(
            features_extractor_class=GfootballImpalaCNN,
            features_extractor_kwargs=dict(features_dim=256),
        )

        parameters = dict(clip_range=0.08, gamma=0.993, learning_rate=0.0003,
                          batch_size=512, n_epochs=10, ent_coef=0.003, max_grad_norm=0.64,
                          vf_coef=0.5, gae_lambda = 0.95,
                          scenario=self.scenario)
        other_info = dict(save_dir=save_dir, total_training_timesteps = total_training_timesteps, eval_freq=eval_freq, )


        model = ALGO("CnnPolicy", env, policy_kwargs=policy_kwargs, verbose=1, tensorboard_log=logdir,
                     clip_range=parameters["clip_range"], gamma= parameters["gamma"], learning_rate = parameters["learning_rate"],
                     batch_size=parameters["batch_size"], n_epochs = parameters["n_epochs"], ent_coef=parameters["ent_coef"],
                     max_grad_norm=parameters["max_grad_norm"], vf_coef=parameters["vf_coef"], gae_lambda=parameters["gae_lambda"])



        #eval_callback = EvalCallback(self.eval_env, best_model_save_path=save_dir,
        #                             log_path=logdir, eval_freq=eval_freq,
        #                             deterministic=True, render=False)

        eval_callback = EvalCallback(model.get_env(), eval_freq=eval_freq, deterministic=True, render=False)

        currentDT = datetime.datetime.now()
        fstr = f"HM_{currentDT.hour}_{currentDT.minute}__DM_{currentDT.day}_{currentDT.month}"
        log_file_name = f"{fstr}"
        parameter_out_file_name = logdir+'/'+log_file_name+".param"



        with open(parameter_out_file_name, "w+") as parout:
            other_info = dict(save_dir=save_dir, total_training_timesteps=total_training_timesteps,
                              eval_freq=eval_freq, parameter_out_file_name = parameter_out_file_name)
            other_info.update(parameters)
            import pprint
            parout.write(pprint.pformat(other_info))

        model.learn(total_timesteps=total_training_timesteps, tb_log_name=log_file_name, callback=eval_callback) #callback=eval_callback

        model.save(f"{save_dir}/PPO_impala_cnn_{total_training_timesteps}")

        mean_reward, std_reward = evaluate_policy(model, model.get_env(), n_eval_episodes=n_eval_episodes)
        print(f"Eval Mean Rewards: {mean_reward:0.4f} Episodes: {n_eval_episodes}")



if __name__ == "__main__":
    import os
    cwd = os.getcwd()
    print("Current working Directory: ", cwd)
    PPO_GF_Impala(level="academy_empty_goal_close").train()


"""
HT 0:  academy_empty_goal_close
"""