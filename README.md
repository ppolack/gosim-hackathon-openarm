#CALIBRATION

#FOLLOWER
lerobot-calibrate     --robot.type=bi_openarm_follower     --robot.left_arm_config.port=can0     --robot.left_arm_config.side=left --robot.right_arm_config.side=right --robot.right_arm_config.port=can1   --robot.id=my_openarm_follower


#LEADER
lerobot-calibrate     --teleop.type=openarm_mini     --teleop.port_left=/dev/ttyACM0 --teleop.port_right=/dev/ttyACM1      --teleop.id=my_openarm_leader

#TELEOPERATION
lerobot-teleoperate     --robot.type=bi_openarm_follower     --robot.left_arm
_config.port=can0     --robot.left_arm_config.side=left     --robot.right_arm_config.port=can1     --robot.right_arm_config.side=right     --robot.id=my_openarm_follower     --teleop.type=openarm_mini     --teleop.port_left=/dev/ttyACM0     --teleop.port_right=/dev/ttyACM1     --teleop.id=my_openarm_leader
