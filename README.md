# GoSIM Hackathon — OpenArm Bimanual Setup with OpenArm Mini Leader

Teleoperation and data-collection workflow for the **bimanual OpenArm** robot using [LeRobot](https://github.com/huggingface/lerobot).

---

Copy calibration files to the LeRobot cache:

```bash
cp -r calib/robots/     ~/.cache/huggingface/lerobot/calibration/robots/
cp -r calib/teleoperators/ ~/.cache/huggingface/lerobot/calibration/teleoperators/
```

Set your Hugging Face username:

```bash
export HF_USER=<your-hf-username>
```

---

## 1. CAN Bus Setup

```bash
# Bring up CAN interfaces
lerobot-setup-can --mode=setup --interfaces=can0,can1

# Verify motor communication
lerobot-setup-can --mode=test --interfaces=can0,can1
```

---

## 2. Find Serial Ports (leader arms)

```bash
lerobot-find-port
```

---

## 3. Calibration

### Follower (bimanual OpenArm)

```bash
lerobot-calibrate \
  --robot.type=bi_openarm_follower \
  --robot.left_arm_config.port=can0 \
  --robot.left_arm_config.side=left \
  --robot.right_arm_config.port=can1 \
  --robot.right_arm_config.side=right \
  --robot.id=my_openarm_follower
```

### Leader (OpenArm Mini)

```bash
lerobot-calibrate \
  --teleop.type=openarm_mini \
  --teleop.port_left=/dev/ttyACM0 \
  --teleop.port_right=/dev/ttyACM1 \
  --teleop.id=my_openarm_leader
```

---

## 4. Teleoperation

```bash
lerobot-teleoperate \
  --robot.type=bi_openarm_follower \
  --robot.left_arm_config.port=can0 \
  --robot.left_arm_config.side=left \
  --robot.right_arm_config.port=can1 \
  --robot.right_arm_config.side=right \
  --robot.id=my_openarm_follower \
  --teleop.type=openarm_mini \
  --teleop.port_left=/dev/ttyACM0 \
  --teleop.port_right=/dev/ttyACM1 \
  --teleop.id=my_openarm_leader
```

---

## 5. Recording a Dataset

> **Before running, verify:**
> - `robot.id` and `teleop.id` match your calibration files
> - CAN ports (`can0` / `can1`) and serial ports (`/dev/ttyACM*`) are correct
> - Camera indices match your physical setup (`index_or_path`)
> - `HF_USER` is set

```bash
lerobot-record \
  --robot.type=bi_openarm_follower \
  --robot.left_arm_config.port=can0 \
  --robot.right_arm_config.port=can1 \
  --robot.id=my_openarm_follower \
  --robot.left_arm_config.cameras='{
    wrist: {"type": "opencv", "index_or_path": 6,  "width": 1280, "height": 720, "fps": 30},
    top:   {"type": "opencv", "index_or_path": 11, "width": 640,  "height": 480, "fps": 30}
  }' \
  --robot.right_arm_config.cameras='{
    wrist: {"type": "opencv", "index_or_path": 11, "width": 1280, "height": 720, "fps": 30}
  }' \
  --teleop.type=openarm_mini \
  --teleop.port_left=/dev/ttyACM0 \
  --teleop.port_right=/dev/ttyACM1 \
  --teleop.id=my_openarm_leader \
  --display_data=true \
  --dataset.repo_id=${HF_USER}/hackathon-gosim-2026 \
  --dataset.num_episodes=25 \
  --dataset.single_task="Grab a bottle and open it" \
  --dataset.streaming_encoding=true \
  --dataset.encoder_threads=2
```

---

## 6. Training a Policy

### 6.1 ACT (recommended starting point)

```bash
lerobot-train \
  --policy.type=act \
  --dataset.repo_id=${HF_USER}/hackathon-gosim-2026 \
  --batch_size=8 \
  --steps=50000 \
  --save_freq=5000 \
  --output_dir=outputs/train/act_openarm
```

### 6.2 SmolVLA (language-conditioned, multi-task)

```bash
lerobot-train \
  --policy.type=smolvla \
  --dataset.repo_id=${HF_USER}/hackathon-gosim-2026 \
  --batch_size=4 \
  --steps=50000 \
  --save_freq=5000 \
  --policy.freeze_vision_encoder=false \
  --policy.train_expert_only=false \
  --output_dir=outputs/train/smolvla_openarm
```

### 6.3 Push checkpoint to Hugging Face Hub

After training finishes (or at any saved checkpoint):

```bash
lerobot-push-policy \
  --policy.path=outputs/train/act_openarm/checkpoints/last \
  --repo_id=${HF_USER}/act-openarm-grab-bottle
```

---

## 7. Inference (Running a Trained Policy on the Robot)

### 7.1 From a local checkpoint

```bash
lerobot-eval \
  --robot.type=bi_openarm_follower \
  --robot.left_arm_config.port=can0 \
  --robot.left_arm_config.side=left \
  --robot.right_arm_config.port=can1 \
  --robot.right_arm_config.side=right \
  --robot.id=my_openarm_follower \
  --robot.left_arm_config.cameras='{
    wrist: {"type": "opencv", "index_or_path": 6,  "width": 1280, "height": 720, "fps": 30},
    top:   {"type": "opencv", "index_or_path": 11, "width": 640,  "height": 480, "fps": 30}
  }' \
  --robot.right_arm_config.cameras='{
    wrist: {"type": "opencv", "index_or_path": 11, "width": 1280, "height": 720, "fps": 30}
  }' \
  --policy.path=outputs/train/act_openarm/checkpoints/last \
  --num_episodes=10
```

### 7.2 From a Hub checkpoint

```bash
lerobot-eval \
  --robot.type=bi_openarm_follower \
  --robot.left_arm_config.port=can0 \
  --robot.left_arm_config.side=left \
  --robot.right_arm_config.port=can1 \
  --robot.right_arm_config.side=right \
  --robot.id=my_openarm_follower \
  --robot.left_arm_config.cameras='{
    wrist: {"type": "opencv", "index_or_path": 6,  "width": 1280, "height": 720, "fps": 30},
    top:   {"type": "opencv", "index_or_path": 11, "width": 640,  "height": 480, "fps": 30}
  }' \
  --robot.right_arm_config.cameras='{
    wrist: {"type": "opencv", "index_or_path": 11, "width": 1280, "height": 720, "fps": 30}
  }' \
  --policy.path=${HF_USER}/act-openarm-grab-bottle \
  --num_episodes=10
```

> **Tips:**
> - Use `--num_episodes=1` for a quick sanity check before running a full eval.
> - If the policy oscillates or freezes, check that camera indices and CAN ports match the training setup exactly.
> - For SmolVLA, pass the task description with `--policy.task="Grab a bottle and open it"` if the checkpoint was trained with language conditioning.

** Tips from lerobot/AGENT-GUIDE.md: **

## 8. Data collection tips (beginner → reliable policy)

Good data beats clever models. Adopt these defaults and deviate only with evidence.

### 8.1 Setup & ergonomics

- **Fix the rig and cameras** before touching the software. If the rig vibrates or the operator gets frustrated, fix that first — more bad data won't help.
- **Lighting matters more than resolution.** Diffuse, consistent light. Avoid moving shadows.
- **"Can you do the task from the camera view alone?"** If no, your cameras are wrong. Fix before recording.
- Enable **action interpolation** for rollouts when available for smoother trajectories.

### 8.2 Practice before you record

- Do 5–10 demos without recording. Build a deliberate, repeatable strategy.
- Hesitant or inconsistent demos teach the model hesitation.

### 8.3 Quality over speed

Deliberate, high-quality execution beats fast sloppy runs. Optimize for speed only **after** strategy is dialed in — never trade quality for it.

### 8.4 Consistency within and across episodes

Same grasp, approach vector, and timing. Coherent strategies are much easier to learn than wildly varying movements.

### 8.5 Start small, then extend (the golden rule)

- **First 50 episodes = constrained version** of the task: one object, fixed position, fixed camera setup, one operator.
- Train a quick ACT model. See what fails.
- **Then add diversity** along one axis at a time: more positions → more lighting → more objects → more operators.
- Don't try to collect the "perfect dataset" on day one. Iterate.

### 8.6 Policy choice for beginners

- **Laptop / first time / want results fast → ACT.** Works surprisingly well, trains fast even on a laptop GPU.
- **Bigger GPU / language-conditioned / multi-task → SmolVLA.** Unfreezing the vision encoder (see §10) is a big win here.
- Defer π0 / π0.5 / Wall-X / X-VLA until you have a proven ACT baseline and a 20+ GB GPU.

### 8.7 Recommended defaults for your first task

| Setting          | Value                                                                                                                                                 |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Episodes         | **50** to start, scale to 100–300 after first training                                                                                                |
| Episode length   | 20–45 s (shorter is fine for grasp/place)                                                                                                             |
| Reset time       | 10 s                                                                                                                                                  |
| FPS              | 30                                                                                                                                                    |
| Cameras          | **2 cameras recommended**: 1 fixed front + 1 wrist. Multi-view often outperforms single-view. A single fixed camera also works to keep things simple. |
| Task description | Short, specific, action-phrased sentence                                                                                                              |

### 8.8 Troubleshooting signal

- Policy fails at one specific stage → record 10–20 more episodes **targeting that stage**.
- Policy flaps / oscillates → likely inconsistent demos, or need more training; re-record worst episodes (use **←** to redo).
- Policy ignores the object → camera framing or lighting issue, not a model issue.

See also: [What makes a good dataset](https://huggingface.co/blog/lerobot-datasets#what-makes-a-good-dataset).

---

## 9. Which policy should I train?

Match the policy to the user's **GPU memory** and **time budget**. Numbers below come from an internal profiling run (one training update per policy). They are **indicative only** — see caveats.

### 9.1 Profiling snapshot (indicative)

All policies typically train for **5–10 epochs** (see §10).

| Policy      | Batch | Update (ms) | Peak GPU mem (GB) | Best for                                                                                         |
| ----------- | ----: | ----------: | ----------------: | ------------------------------------------------------------------------------------------------ |
| `act`       |     4 |    **83.9** |          **0.94** | First-time users, laptops, single-task. Fast and reliable.                                       |
| `diffusion` |     4 |       168.6 |              4.94 | Multi-modal action distributions; needs mid-range GPU.                                           |
| `smolvla`   |     1 |       357.8 |              3.93 | Language-conditioned, multi-task, small VLA. **Unfreeze vision encoder for big gains** (see §7). |
| `xvla`      |     1 |       731.6 |             15.52 | Large VLA, multi-task.                                                                           |
| `wall_x`    |     1 |       716.5 |             15.95 | Large VLA with world-model objective.                                                            |
| `pi0`       |     1 |       940.3 |             15.50 | Strong large VLA baseline (Physical Intelligence).                                               |
| `pi05`      |     1 |      1055.8 |             16.35 | Newer π policy; similar footprint to `pi0`.                                                      |

**Critical caveats:**

- **Optimizer:** measured with **SGD**. LeRobot's default is **AdamW**, which keeps extra optimizer state → **peak memory will be noticeably higher** with the default, especially for `pi0`, `pi05`, `wall_x`, `xvla`.
- **Batch size:** the large policies were profiled at batch 1. In practice use a **larger batch** for stable training (see §10.4). Memory scales roughly linearly with batch.

### 9.2 Decision rules

- **< 8 GB VRAM (laptop, 3060, M-series Mac):** → `act`. Maybe `diffusion` if you have ~6–8 GB free.
- **12–16 GB VRAM (4070/4080, A4000):** → `smolvla` with defaults, or `act`/`diffusion` with larger batch. `pi0`/`pi05`/`wall_x`/`xvla` feasible only with small batch + gradient accumulation.
- **24+ GB VRAM (3090/4090/A5000):** → any policy. Prefer `smolvla` (unfrozen) for multi-task; `act` for single-task grasp-and-place (still often the best ROI). Could experiment with `pi0` or `pi05` or `xvla`
- **80 GB (A100/H100):** → any, with healthy batch. `pi05`, `xvla`, `wall_x` become comfortable.
- **CPU only:** → don't train here. Use Google Colab (see [`docs/source/notebooks.mdx`](./docs/source/notebooks.mdx)) or a rented GPU.

---

## 10. How long should I train?

Robotics imitation learning usually converges in a **few epochs over the dataset**, not hundreds of thousands of raw steps. Think **epochs first**, then translate to steps.

### 10.1 Rule of thumb

- **Typical total: 5–10 epochs.** Start at 5, eval, then decide if more helps.
- Very small datasets (< 30 episodes) may want slightly more epochs — but first, **collect more data**.
- VLAs with a pretrained vision backbone typically need **fewer** epochs than training from scratch.

### 10.2 Steps ↔ epochs conversion

```
total_frames     = sum of frames over all episodes      # e.g. 50 eps × 30 fps × 30 s ≈ 45,000
steps_per_epoch  = ceil(total_frames / batch_size)
total_steps      = epochs × steps_per_epoch
```

Examples for `--batch_size=8`:

| Dataset size            |  Frames | Steps / epoch | 5 epochs | 10 epochs |
| ----------------------- | ------: | ------------: | -------: | --------: |
| 50 eps × 30 s @ 30 fps  |  45,000 |        ~5,625 |      28k |       56k |
| 100 eps × 30 s @ 30 fps |  90,000 |       ~11,250 |      56k |      113k |
| 300 eps × 30 s @ 30 fps | 270,000 |       ~33,750 |     169k |      338k |

Pass the resulting total with `--steps=<N>`; eval at intermediate checkpoints (`outputs/train/.../checkpoints/`).

### 10.3 Per-policy starting points (single-task, ~50 episodes)

| Policy         | Batch | Steps (first run) | Notes                                                             |
| -------------- | ----: | ----------------: | ----------------------------------------------------------------- |
| `act`          |  8–16 |           30k–80k | Usually converges under 50k for single-task.                      |
| `diffusion`    |  8–16 |          80k–150k | Benefits from longer training than ACT.                           |
| `smolvla`      |   4–8 |           30k–80k | Pretrained VLM → converges fast.                                  |
| `pi0` / `pi05` |   1–4 |           30k–80k | Memory-bound; use gradient accumulation for effective batch ≥ 16! |

### 10.4 Batch size guidance

- **Bigger batch is preferable** for stable gradients on teleop data.
- If GPU memory is the bottleneck, use **gradient accumulation** to raise _effective_ batch without raising peak memory.
- Scale **learning rate** gently with batch; most LeRobot defaults work fine for a 2–4× batch change.

### 10.5 Scale LR schedule & checkpoints with `--steps`

LeRobot's default schedulers (e.g. SmolVLA's cosine decay) use `scheduler_decay_steps=30_000`, which is sized for long training runs. When you shorten training (e.g. 5k–10k steps on a small dataset), **scale the scheduler down to match** — otherwise the LR stays near the peak and never decays. Same for checkpoint frequency.

```bash
lerobot-train ... \
  --steps=5000 \
  --policy.scheduler_decay_steps=5000 \
  --save_freq=5000
```

Rule of thumb: set `scheduler_decay_steps ≈ steps`, and `save_freq` to whatever granularity you want for eval (e.g. every 1k–5k steps). Match `scheduler_warmup_steps` proportionally if your run is very short.

### 10.6 SmolVLA: unfreeze the vision encoder for real gains

SmolVLA ships with `freeze_vision_encoder=True`. Unfreezing usually **improves performance substantially** on specialized tasks, at the cost of more VRAM and slower steps. Enable with:

```bash
lerobot-train ... --policy.type=smolvla \
  --policy.freeze_vision_encoder=false \
  --policy.train_expert_only=false
```

### 10.7 Signals to stop / keep going

- Train loss plateaus → stop, save a Hub checkpoint.
- Train loss still dropping and you're under 10 epochs → keep going.
