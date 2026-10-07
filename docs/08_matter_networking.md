# 08 — Matter / Networking

## Technologies under study

- Thread
- Wi-Fi
- Ethernet
- BLE

## Important architectural question

The available project material leaves open whether LOT is intended primarily as:

1. a Matter/Thread border-router-oriented block, or
2. a downstream data-plane/accelerator block behind a host/router.

This must be confirmed before final endpoint interfaces are frozen.

## Engineering approach

Study the networking technologies at the interface boundary required by the actual LOT role. Do not build radio protocol logic inside the generic crossbar.
