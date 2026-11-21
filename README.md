# emacs-fedora-docker

Docker image of GNU Emacs built from **master** on Fedora Rawhide.

Matches the configuration used in [emacs-fedora-dynamic](https://github.com/danrobi11/emacs-fedora-dynamic):

- Terminal only (`--without-x` etc.)
- No modules, no native compilation

## How to

The container uses the host program directories and libraries, the host process list, and the X socket. `/dev/fuse` lets AppImages mount. `/dev/dri`, `/dev/shm`, and the EGL vendor file let mpv open a GPU window. `podman` is the host client pointed at the host socket, so it does not join the container user namespace.

```bash
podman pull ghcr.io/danrobi11/my-emacs-fedora-docker-image:latest

mkdir -p /var/home/danrobi/.cache/emacs-container-run/podman

podman run -it --rm --name emacs \
  --security-opt label=disable \
  --userns=keep-id \
  --pid=host \
  --device /dev/fuse \
  --device /dev/dri \
  --device /dev/snd \
  -e HOME=/var/home/danrobi \
  -e DISPLAY="$DISPLAY" \
  -v /var/home/danrobi:/var/home/danrobi \
  -v /var/home/danrobi:/home/danrobi \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /dev/shm:/dev/shm \
  -v /usr/bin:/usr/bin:ro \
  -v /usr/lib64:/usr/lib64:ro \
  -v /usr/lib:/usr/lib:ro \
  -v /usr/libexec:/usr/libexec:ro \
  -v /usr/share/dict:/usr/share/dict:ro \
  -v /usr/share/glvnd:/usr/share/glvnd:ro \
  -v /run/user/1000/podman/podman.sock:/var/home/danrobi/.cache/emacs-container-run/podman/podman.sock \
  -v /var/home/danrobi/.emacs.d/emacs-scripts/podman-remote:/usr/local/bin/podman:ro \
  -v /:/run/host:rslave \
  -w /var/home/danrobi \
  ghcr.io/danrobi11/my-emacs-fedora-docker-image:latest emacs -nw
```

Sound and the GPU card node also need an access-control entry for this user:

```bash
sudo setfacl -m u:danrobi:rw /dev/snd/* /dev/dri/card0
```

`/dev/snd/*` is `root:audio` and `/dev/dri/card0` is `root:video`, both mode `660`. On the host, danrobi is in the `audio` group, so mpv can open ALSA card 1 and the card node. This container is rootless. The `audio` and `video` group ids are not in `/etc/subgid`, so the kernel drops those groups inside the container. The process is still uid 1000, and the device nodes refuse the open. The `setfacl` line grants uid danrobi access on the nodes, so the groups are not required. Udev recreates these nodes at boot, and the entries are gone until the command is run again.
