# emacs-fedora-docker

Docker image of GNU Emacs built from **master** on Fedora Rawhide.

Matches the configuration used in [emacs-fedora-dynamic](https://github.com/danrobi11/emacs-fedora-dynamic):

- Terminal only (`--without-x` etc.)
- No modules, no native compilation

## How to

The container uses the host program directories and libraries, the host process list, and the X socket. `/dev/fuse` lets AppImages mount. `/dev/dri`, `/dev/shm`, and the EGL vendor file let mpv open a GPU window.

```bash
podman pull ghcr.io/danrobi11/my-emacs-fedora-docker-image:latest

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
  -v /usr/share/glvnd:/usr/share/glvnd:ro \
  -v /:/run/host:rslave \
  -w /var/home/danrobi \
  ghcr.io/danrobi11/my-emacs-fedora-docker-image:latest emacs -nw
```
