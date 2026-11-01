# Nyxuri Orbit attribution

OrbitMath.js and OrbitContent.qml adapt the geometry, spring integration and
capsule/ring rendering design of **Nyxuri Orbit**, by ech678 and contributors:
https://github.com/ech678/Nyxuri

Reference revision: `c3e53976b8409047ff0eb5fdb891327760dd7ae1`.
Source files: `plugins/noctalia/tools/orbit/{physics,renderer,window,config}.py`.
Licensed under GPL-3.0; see the repository's root LICENSE.

This is a Qt Quick port, not the original GTK application. It uses the host
shell's palette, settings, lock and wallpaper services. The original Cairo
search-hub rendering, scratchpad script integration, and TOML loader are not
included; search uses Qt's native text input and customization uses JSON.
