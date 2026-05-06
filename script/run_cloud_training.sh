TRAINING_DATASET_NAME="gosim-hackathon-2026-merged"

POLICY_TYPE="act" #see list on lerobot
POLICY_REPO_NAME="act_openarm_pickandhandover_policy"

HF_USER="thanhndv212" # set your Hugging Face username here, e.g. "john_doe"

# train using the chosen policy
lerobot-train \
  --dataset.repo_id=rdesarz/gosim-hackathon-2026-merged \
  --policy.type=${POLICY_TYPE} \
  --output_dir=outputs/train/${POLICY_TYPE}_${TRAINING_DATASET_NAME} \
  --job_name=${POLICY_TYPE}_${TRAINING_DATASET_NAME} \
  --batch_size=8 \
  --steps=30000 \
  --save_freq=5000 \
  --policy.device=cuda \
  --wandb.enable=true \
  --policy.repo_id=${HF_USER}/${POLICY_REPO_NAME}

# When training done
hf upload ${HF_USER}/${POLICY_TYPE}_${TRAINING_DATASET_NAME} \
  outputs/train/${POLICY_TYPE}_${TRAINING_DATASET_NAME}/checkpoints/last/pretrained_model