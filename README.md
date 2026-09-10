# nimbus-feeder

Makes a SteelSeries Nimbus (the old iOS MFi controller) show up on Linux as a
proper Xbox 360 gamepad, over Bluetooth.

Pair the Nimbus normally and Linux does pick it up as a joystick already,
but the mapping is garbage. Buttons are shifted, the right stick fights the
left one, Start sends a browser-home keypress, and the dpad just doesn't
work at all. That last one isn't a Linux bug specifically; it's a known
issue with this controller even on Apple's own platforms. The real cause is
BlueZ's Bluetooth HID translation mangling this device's report layout on
its way into the kernel.

So this skips that layer entirely. It reads the raw HID reports straight off
`/dev/hidraw`, decodes them by hand, and writes a clean virtual Xbox 360
controller through `uinput`. No config, no mapping editor, one script.

## Why

Years ago [MFIGamepadFeeder](https://github.com/Axadiw/MFIGamepadFeeder) by
Michał Mizera (Axadiw) let me use this same Nimbus on Windows, which got a
lot of couch co-op sessions out of it with friends. Wanted the same thing on
Linux, minus all the Windows-only bits (ViGEm driver, config editor). Just
the part that makes the controller work.

## Install

```
git clone <this repo>
cd nimbus-feeder
./omarchy/install.sh
```

On Omarchy this installs the script to `~/.local/bin`, adds a udev rule so
your user can read the Nimbus's `hidraw` node without root, and installs a
bar-widget plugin (a gamepad icon; click it to arm/disarm the bridge, see
live status, and get told if something's wrong). The udev rule needs a
**reboot** to take effect — a relogin isn't enough, since your desktop
session's group membership only refreshes on a fresh login.

Not on Omarchy? Just:

```
cp nimbus-feeder ~/.local/bin/
chmod +x ~/.local/bin/nimbus-feeder
```

You'll need your own way to let your user read `/dev/hidraw*` (root-only by
default) — either adapt `udev/99-nimbus.rules`, or just run it with `sudo`.

## Run

Pair the Nimbus over Bluetooth first, then either click the bar-widget icon
to arm it, or run it directly:

```
nimbus-feeder
```

(`sudo nimbus-feeder` if you skipped the udev rule.) It loops forever,
printing `WAITING` while no controller is connected and `ACTIVE` once it's
bridged — reconnect the Nimbus as many times as you like without restarting
it. Ctrl+C (or SIGTERM) stops it and tears the virtual controller down
cleanly.

## What doesn't work

The Nimbus itself doesn't have a Select/Back button or clickable thumbsticks,
so those Xbox inputs are declared but never fire. Nothing to fix there,
it's just the hardware.

## The HID report, for anyone else reverse-engineering this thing

17 bytes, no report ID byte, one byte per control:

```
offset 0-3    dpad up, right, down, left   (each 0-255, analog-ish pressure curve)
offset 4-7    A, B, X, Y
offset 8-9    LB, RB
offset 10-11  LT, RT                        (genuinely analog)
offset 12     Start
offset 13-16  left stick X, left stick Y, right stick X, right stick Y   (signed, -127..127)
```

Everything in 0-12 is nominally a button, but the device reports it as a
ramping 0-255 value rather than a flat 0/1. Thresholding at ~30 works fine.
Couldn't find this documented anywhere else, so here it is.

## License

MIT, see LICENSE.
