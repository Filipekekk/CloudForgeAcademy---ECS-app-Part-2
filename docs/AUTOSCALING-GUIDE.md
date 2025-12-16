# Auto-Scaling Guide

## Configuration

**Scale-Out**: CPU > 50% → Add task (max 3)
**Scale-In**: CPU < 25% for 5 minutes → Remove task (min 1)

## Testing

```bash
cd scripts
./test-autoscaling.sh
```

## Monitoring

```bash
# Current task count
make ecs-status

# Scaling activity
make scaling-activity

# CloudWatch logs
make logs
```

## Tuning

Edit `modules/ecs/autoscaling.tf`:

```hcl
# Change thresholds
target_value = 60.0  # Scale at 60% instead of 50%
threshold = 20.0     # Scale down at 20% instead of 25%

# Change cooldowns
scale_out_cooldown = 30   # React faster (30s)
scale_in_cooldown = 600   # Wait longer before scaling in (10min)
```

## Expected Behavior

| Time | Event | Tasks |
|------|-------|-------|
| 0:00 | Normal load | 1 |
| 0:30 | CPU > 50% | 2 (scaling) |
| 5:00 | Load stops | 2 |
| 10:05 | CPU < 25% for 5min | 1 (scaling in) 