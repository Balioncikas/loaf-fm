# Background opacity

Open **Settings → Interface → Background opacity** to choose between 0% and
100%. The default is 100% (solid). Text, icons, menus, dialogs and selection
colors remain opaque. Low-power mode temporarily restores solid backgrounds
without losing the saved opacity preference.

Opacity fades the window itself, so at low values the wallpaper shows through
the margins, gaps and empty space. Surfaces that carry text — the file panes,
the sidebar and settings cards — keep a minimum backing (65% of their surface
color), because labels drawn straight onto a wallpaper cannot stay readable in
both light and dark mode. That floor is `containerAlphaFloor` in `Theme.qml`.

Background blur is supplied by your desktop compositor. Enable blur for Loaf
in your desktop effects or compositor rules. Loaf's Wayland app ID is `loaf`.
On desktops without blur, reduced opacity still works when compositing supports
transparency, but the background will be unblurred. Set opacity to 100% to
restore a solid window.

For a local development trial, build with `cargo build` and run
`./target/debug/loaf --new-window`. This avoids claiming the desktop's
`org.freedesktop.FileManager1` service. It does not change the default file
manager association. An already running regular Loaf instance may have claimed
that service earlier.

To check theme defaults, invalid saved values, opaque foreground colors,
low-power behavior and persistence across launches:

```sh
cargo build
python3 tests/check-background-opacity.py
```

The check runs the real QML theme through Loaf using temporary settings
directories and Qt's offscreen platform. Also test visually on a desktop with
compositing: adjust the slider in both directions, check split view, settings
search, light/dark palettes, popup readability, keyboard adjustment and restoring
100% opacity. Offscreen checks cannot verify your compositor's blur.
