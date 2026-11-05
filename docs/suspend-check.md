# Measure battery drain during suspend

```
suspend-check
```

Suspends, then on wake prints how long it slept, the share spent in deep sleep and the average drain. Sleep for at least 30 minutes for a reliable number. A few hundred mW is good; watts means something kept the system awake (`sudo powertop` shows devices blocking idle).
