#!/bin/bash

# Setting the HF environment
source env/private.env 

hf auth login --token ${HF_TOKEN} --add-to-git-credential

HF_USER=$(hf auth whoami | grep -oP '(?<=user:\s)\S+')

echo ${HF_USER}


# Recording
# Tips: for the recording https://huggingface.co/docs/lerobot/il_robots#record-a-dataset
# --control.push_to_hub=true to push dataset to HF hub (dataset visualisation tool https://huggingface.co/spaces/lerobot/visualize_dataset)
# --dataset.episode_time_s=60 Duration of each data recording episode (default: 60 seconds).
# --dataset.reset_time_s=60 Duration for resetting the environment after each episode (default: 60 seconds).
# --dataset.num_episodes=50 Total number of episodes to record (default: 50).

TRAINING_DATASET_NAME="hackathon-gosim-2026_training"
TESTING_DATASET_NAME="hackathon-gosim-2026_eval"
DATASET_TASK="Make the kids sleep"

POLICY_TYPE="act" #see list on lerobot
POLICY_REPO_NAME="act_policy"

lerobot-record \
  --robot.type=bi_so_follower \
  --robot.left_arm_config.port=/dev/can0 \
  --robot.right_arm_config.port=/dev/can1 \
  --robot.id=bimanual_follower \
  --robot.left_arm_config.cameras='{
    wrist: {"type": "opencv", "index_or_path": 6, "width": 1280, "height": 720, "fps": 30},
    top: {"type": "opencv", "index_or_path": 11, "width": 640, "height": 480, "fps": 30},
  }' \
  --robot.right_arm_config.cameras='{
    wrist: {"type": "opencv", "index_or_path": 11, "width": 1280, "height": 720, "fps": 30},
  }' \
  --teleop.type=bi_so_leader \
  --teleop.left_arm_config.port=/dev/ttyACM0 \
  --teleop.right_arm_config.port=/dev/ttyACM1 \
  --teleop.id=bimanual_leader \
  --display_data=true \
  --dataset.repo_id=${HF_USER}/${TRAINING_DATASET_NAME} \
  --dataset.num_episodes=25 \
  --dataset.single_task=${DATASET_TASK} \
  --dataset.streaming_encoding=true \
  --dataset.encoder_threads=2 \
  --control.push_to_hub=true

#replay episode
EPISODE_NUMBER=0
lerobot-replay \
  --robot.type=bi_so_follower \
  --robot.left_arm_config.port=/dev/can0 \
  --robot.right_arm_config.port=/dev/can1 \
  --robot.id=bimanual_follower \
  --robot.left_arm_config.cameras='{
    wrist: {"type": "opencv", "index_or_path": 6, "width": 1280, "height": 720, "fps": 30},
    top: {"type": "opencv", "index_or_path": 11, "width": 640, "height": 480, "fps": 30},
  }' \
  --robot.right_arm_config.cameras='{
    wrist: {"type": "opencv", "index_or_path": 11, "width": 1280, "height": 720, "fps": 30},
  }' \
  --dataset.repo_id=${HF_USER}/record-test \
  --control.push_to_hub=false \
  --dataset.episode=${EPISODE_NUMBER}

# train using the chosen policy
lerobot-train \
  --dataset.repo_id=${HF_USER}/${TRAINING_DATASET_NAME} \
  --policy.type=${POLICY_TYPE} \
  --output_dir=outputs/train/${POLICY_TYPE}_${TRAINING_DATASET_NAME} \
  --job_name=${POLICY_TYPE}_${TRAINING_DATASET_NAME} \
  --policy.device=cuda \
  --wandb.enable=true \
  --policy.repo_id=${HF_USER}/${POLICY_REPO_NAME}

# When training done
hf upload ${HF_USER}/${POLICY_TYPE}_${TRAINING_DATASET_NAME} \
  outputs/train/${POLICY_TYPE}_${TRAINING_DATASET_NAME}/checkpoints/last/pretrained_model

# Run inference
lerobot-record  \
  --robot.type=bi_so_follower \
  --robot.left_arm_config.port=/dev/can0 \
  --robot.right_arm_config.port=/dev/can1 \
  --robot.id=bimanual_follower \
  --robot.left_arm_config.cameras='{
    wrist: {"type": "opencv", "index_or_path": 6, "width": 1280, "height": 720, "fps": 30},
    top: {"type": "opencv", "index_or_path": 11, "width": 640, "height": 480, "fps": 30},
  }' \
  --robot.right_arm_config.cameras='{
    wrist: {"type": "opencv", "index_or_path": 11, "width": 1280, "height": 720, "fps": 30},
  }' \
  
  --display_data=false \
  --dataset.repo_id=${HF_USER}/${TESTING_DATASET_NAME} \
  --dataset.single_task=${DATASET_TASK} \
  --dataset.streaming_encoding=true \
  --dataset.encoder_threads=2 \
  # --dataset.vcodec=auto \
  # <- Teleop optional if you want to teleoperate in between episodes \
  #   --teleop.type=bi_so_leader \
  #   --teleop.left_arm_config.port=/dev/ttyACM0 \
  #   --teleop.right_arm_config.port=/dev/ttyACM1 \
  #   --teleop.id=bimanual_leader \
  --policy.path=${HF_USER}/${POLICY_REPO_NAME}