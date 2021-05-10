#!/bin/bash

python3 -u -m gfrl.base.run_my_ppo2 \
  --level ../_scenarios/sc4rl/ps_3v2_0.scenic  \
  --eval_level ../_scenarios/sc4rl/ps_3v2_0.scenic  \
  --reward_experiment scoring \
  --policy gfootball_impala_cnn \
  --cliprange 0.115 \
  --gamma 0.997 \
  --ent_coef 0.00155 \
  --num_timesteps 1000000 \
  --max_grad_norm 0.76 \
  --lr 0.00011879 \
  --num_envs 16 \
  --noptepochs 2 \
  --nminibatches 4 \
  --nsteps 512 \
  --save_interval 10 \
  --eval_interval  5 \
  --exp_root ../_resv2/sc4rl \
  --exp_name pass_3v2_0 \
  "$@"


python3 -u -m gfrl.base.run_my_ppo2 \
  --level ../_scenarios/sc4rl/ps_3v2_1.scenic  \
  --eval_level ../_scenarios/sc4rl/ps_3v2_1.scenic  \
  --reward_experiment scoring \
  --policy gfootball_impala_cnn \
  --cliprange 0.115 \
  --gamma 0.997 \
  --ent_coef 0.00155 \
  --num_timesteps 1000000 \
  --max_grad_norm 0.76 \
  --lr 0.00011879 \
  --num_envs 16 \
  --noptepochs 2 \
  --nminibatches 4 \
  --nsteps 512 \
  --save_interval 10 \
  --eval_interval  5 \
  --exp_root ../_resv2/sc4rl \
  --exp_name pass_3v2_1 \
  "$@"
