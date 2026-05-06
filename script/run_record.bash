#!/bin/bash

clear

rm -rf /home/rdesarz/.cache/huggingface/lerobot/rdesarz/gosim-hackathon-2026

lerobot-record \
  --robot.type=bi_openarm_follower \
  --robot.left_arm_config.port=can0 \
  --robot.right_arm_config.port=can1 \
  --robot.id=my_openarm_follower \
  --robot.left_arm_config.side=left \
  --robot.right_arm_config.side=right \
  --teleop.type=openarm_mini \
  --robot.cameras='{
    right_wrist: {"type": "opencv", "index_or_path": 4, "width": 1280, "height": 720, "fps": 30},
    left_wrist: {"type": "opencv", "index_or_path": 6, "width": 1280, "height": 720, "fps": 30},
    top: {"type": "opencv", "index_or_path": 8, "width": 640, "height": 480, "fps": 30},
  }' \
  --teleop.port_left=/dev/ttyACM0 \
  --teleop.port_right=/dev/ttyACM1 \
  --teleop.id=my_openarm_leader \
  --display_data=true \
  --dataset.repo_id=rdesarz/gosim-hackathon-2026 \
  --dataset.num_episodes=25 \
  --dataset.single_task="Grab some tools" \
  --dataset.streaming_encoding=true \
  --dataset.encoder_threads=2

