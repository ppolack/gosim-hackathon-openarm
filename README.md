#CALIBRATION

#FOLLOWER
lerobot-calibrate     --robot.type=bi_openarm_follower     --robot.left_arm_config.port=can0     --robot.left_arm_config.side=left --robot.right_arm_config.side=right --robot.right_arm_config.port=can1   --robot.id=my_openarm_follower


#LEADER
lerobot-calibrate     --teleop.type=openarm_mini     --teleop.port_left=/dev/ttyACM0 --teleop.port_right=/dev/ttyACM1      --teleop.id=my_openarm_leader

#TELEOPERATION
lerobot-teleoperate --robot.type=bi_openarm_follower --robot.left_arm_config.port=can0 --robot.left_arm_config.side=left --robot.right_arm_config.port=can1 --robot.right_arm_config.side=right  --robot.id=my_openarm_follower --teleop.type=openarm_mini --teleop.port_left=/dev/ttyACM0 --teleop.port_right=/dev/ttyACM1 --teleop.id=my_openarm_leader


# Recording

lerobot-record --robot.type=bi_so_follower --robot.left_arm_config.port=/dev/can0 --robot.right_arm_config.port=/dev/can1 --robot.id=bimanual_follower --robot.left_arm_config.cameras='{
    wrist: {"type": "opencv", "index_or_path": 6, "width": 1280, "height": 720, "fps": 30},
    top: {"type": "opencv", "index_or_path": 11, "width": 640, "height": 480, "fps": 30},
  }' --robot.right_arm_config.cameras='{
    wrist: {"type": "opencv", "index_or_path": 11, "width": 1280, "height": 720, "fps": 30},
  }' --teleop.type=bi_so_leader --teleop.left_arm_config.port=/dev/ttyACM0 --teleop.right_arm_config.port=/dev/ttyACM1 --teleop.id=bimanual_leader --display_data=true --dataset.repo_id=${HF_USER}/hackathon-gosim-2026 --dataset.num_episodes=25 --dataset.single_task="Grab a bottle and open it" --dataset.streaming_encoding=true --dataset.encoder_threads=2