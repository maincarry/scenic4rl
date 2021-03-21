import gym, ray
from ray.tune.registry import register_env
import numpy as np
import ray
from ray import tune
from ray.rllib.models import ModelCatalog
from ray.rllib.models.torch.torch_modelv2 import TorchModelV2

from ray.rllib.utils.framework import try_import_tf, try_import_torch
torch, nn = try_import_torch() 

class DummyGFEnv(gym.Env):
    def __init__(self):
        self.observation_space = gym.spaces.Box(low=0, high=255, shape=(72, 96, 16), dtype=np.uint8)
        self.action_space = gym.spaces.discrete.Discrete(19)

    def reset(self):
        return np.zeros((72,96,16), dtype=np.uint8)

    def step(self, action):
        return np.zeros((72,96,16), dtype=np.uint8), 0, False, {}

def env_creator(env_config):
    from scenic.simulators.gfootball.rl_interface import GFScenicEnv
    gf_env_settings = {
                "stacked": True,
                "rewards": 'scoring,checkpoints',
                "representation": 'extracted',
                "players": [f"agent:left_players=1"],
                "real_time": False,
                "action_set": "default"
            }

    from scenic.simulators.gfootball.utilities.scenic_helper import buildScenario
    scenario_file = f"academy_empty_goal_close.scenic"
    scenario = buildScenario(scenario_file)
    env = GFScenicEnv(initial_scenario=scenario, gf_env_settings=gf_env_settings)
    print("env instance created")
    return env

def dummy_env_creator(something):
    return DummyGFEnv()

ray.init()


class GFImpalaTorch(TorchModelV2, nn.Module):
    """Custom model for policy gradient algorithms."""

    def create_basic_res_block(self, in_channel, out_channel):
        return nn.Sequential(
            nn.ReLU(),
            nn.Conv2d(in_channels=in_channel, out_channels=out_channel, kernel_size=3, stride=1, padding=1),
            nn.ReLU(),
            nn.Conv2d(in_channels=out_channel, out_channels=out_channel, kernel_size=3, stride=1, padding=1),
        )

    def __init__(self, obs_space, action_space, num_outputs, model_config,
                 name):
        nn.Module.__init__(self)
        super(GFImpalaTorch, self).__init__(obs_space, action_space, None,
                                                 model_config, name)

        self.conv_layers_config = [(16, 2), (32, 2), (32, 2), (32, 2)]
        self.pool = nn.MaxPool2d(kernel_size=3, stride=2)

        n_input_channels = 16

        self.conv_blocks = [
            nn.Conv2d(in_channels=n_input_channels, out_channels=16, kernel_size=3, stride=1, padding=1),
            nn.Conv2d(in_channels=16, out_channels=32, kernel_size=3, stride=1, padding=1),
            nn.Conv2d(in_channels=32, out_channels=32, kernel_size=3, stride=1, padding=1),
            nn.Conv2d(in_channels=32, out_channels=32, kernel_size=3, stride=1, padding=1)
        ]

        #https://www.tensorflow.org/api_docs/python/tf/nn/pool  -> If padding = "SAME": output_spatial_shape[i] = ceil(input_spatial_shape[i] / strides[i])
        self.pools = [nn.MaxPool2d(kernel_size=3, stride=2, padding=1) for _ in range(4)]

        self.resblocks_1 = [
            self.create_basic_res_block(16, 16),
            self.create_basic_res_block(32, 32),
            self.create_basic_res_block(32, 32),
            self.create_basic_res_block(32, 32)
        ]
        self.resblocks_2 = [
            self.create_basic_res_block(16, 16),
            self.create_basic_res_block(32, 32),
            self.create_basic_res_block(32, 32),
            self.create_basic_res_block(32, 32)
        ]

        self.relu = nn.ReLU()
        self.flatten = nn.Flatten()
        self.linear = nn.Sequential(nn.Linear(960, 256), nn.ReLU()) #n_flatten=960, features_dim = 256



    def forward(self, input_dict, state, seq_lens):

        observations = input_dict["obs"]
        #print("ZZZZ", observations.shape, observations.dtype)
        observations = observations.float()
        observations = observations.permute(0,3,1,2)
        #print("ZZZZ input channel swapped", observations.shape, observations.dtype)
        #observations = th.FloatTensor(observations)
        observations /= 255.0


        conv_out = observations
        for i in range(4):
            conv_out = self.conv_blocks[i](conv_out)
            #print(f"ZZZZ conv_{i}: ", conv_out.shape)
            conv_out = self.pools[i](conv_out)
            #print(f"ZZZZ pool_{i}: ", conv_out.shape)

            block_input = conv_out
            conv_out = self.resblocks_1[i](conv_out)
            conv_out += block_input

            block_input = conv_out
            conv_out = self.resblocks_2[i](conv_out)
            conv_out += block_input
            #print(f"ZZZZ block_{i}: ", conv_out.shape)

        #print("ZZZZ relu in ", conv_out.shape)
        conv_out = self.relu(conv_out)
        #print("ZZZZ flatten in", conv_out.shape)
        conv_out = self.flatten(conv_out)
        #print("ZZZZ flatten out", conv_out.shape)
        conv_out = self.linear(conv_out)
        print("ZZZZ linnear out", conv_out.shape)


        self._output = conv_out
        return conv_out, state 

    
    def value_function(self):
        assert self._output is not None, "must call forward first!"
        value_out = torch.reshape(self._output, [-1])
        print("ZZZZ value function out shape", value_out.shape)
        return value_out


register_env("my_env", dummy_env_creator)
ModelCatalog.register_custom_model("gf_impala_cnn_ppo_torch", GFImpalaTorch)


from ray.rllib.agents.ppo import PPOTrainer
tune.run(PPOTrainer, config={
    "env": "my_env", 
    "num_workers": 2,
    'model': {
        "custom_model": "gf_impala_cnn_ppo_torch"
        },
    "framework": "torch",
}) 

#create custom environment
#https://github.com/ray-project/ray/issues/3111  


"""
    'model': {
                    'dim':96,
                'conv_filters': [
                    [96,16,96]
                ],
                'fcnet_hiddens': [256, 256],
                'use_lstm': False,
            }
"""
