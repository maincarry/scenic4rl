#!/bin/bash

python3 -u -m gfrl.base.run_my_ppo2 \
  --level ../_scenarios/generic/rts/gen_0.scenic  \
  --eval_level ../_scenarios/academy/rts.scenic  \
  --reward_experiment scoring \
  --policy impala_cnn \
  --cliprange 0.115 \
  --gamma 0.997 \
  --ent_coef 0.00155 \
  --num_timesteps 500000 \
  --max_grad_norm 0.76 \
  --lr 0.00011879 \
  --num_envs 16 \
  --noptepochs 2 \
  --nminibatches 4 \
  --nsteps 512 \
  --save_interval 10 \
  --eval_interval 10 \
  --exp_root ../_res \
  --exp_name generic_rts \
  "$@"

# Needed to add: max_grad_norm

# Good but unsettable defaults:
# Optimizer: adam
# Value-function coefficient is 0.5
# GAE (lam): 0.95
