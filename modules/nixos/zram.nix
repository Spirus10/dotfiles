{ ... }:

{
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    # 50% of RAM as compressed swap. Effective capacity ~1.5-2x this
    # after zstd compression on typical workloads.
    memoryPercent = 50;
  };
}
