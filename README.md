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
  -e TERM=xterm-256color \
  -e PATH="$PATH" \
  -e APPIMAGE_EXTRACT_AND_RUN=1 \
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

Sound and the GPU card node also need an access-control entry for this user. `/dev/snd/*` is `root:audio` and `/dev/dri/card0` is `root:video`, both mode `660`. On the host, danrobi is in the `audio` group, so mpv can open ALSA card 1. This container is rootless. The `audio` and `video` group ids are not in `/etc/subgid`, so the kernel drops those groups inside the container. The process is still uid 1000, and the device nodes refuse the open.

Temporary fix:

```bash
sudo setfacl -m u:danrobi:rw /dev/snd/* /dev/dri/card0
```

Those nodes are already tagged `uaccess`, which is how logind grants the entry to the active seat session. This machine starts X with `startx`, and that session does not stay active, so logind removes the entry. A manual `setfacl` lasts until the next boot. `99-danrobi-snd-dri.rules` drops the `uaccess` tag and runs `setfacl` whenever udev creates the nodes:

```bash
sudo cp /var/home/danrobi/.emacs.d/emacs-docker-image/99-danrobi-snd-dri.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger --action=add --subsystem-match=sound
sudo udevadm trigger --action=add --sysname-match=card0
```
## Fix the `yank-from-kill-ring` issue with xclip.

Add this function in your init.el:

```bash
(defun my-clipboard-keep-import (&rest _args)
  "Add clipboard-keep history to `kill-ring'."
  (let ((dir (expand-file-name "clipboard-keep/clips"
                                (or (getenv "XDG_DATA_HOME")
                                    "~/.local/share"))))
    (when (file-directory-p dir)
      (dolist (file (directory-files dir t "\\`[0-9]+\\'"))
        (let ((text (with-temp-buffer
                      (insert-file-contents file)
                      (buffer-string))))
          (unless (or (string-empty-p text)
                      (seq-some (lambda (item) (string= item text)) kill-ring))
            (push text kill-ring)))))))

(advice-add 'read-from-kill-ring :before #'my-clipboard-keep-import)
```

Create this file:

```bash
/var/home/danrobi/bin/clipboard-keep
```
Add this in /var/home/danrobi/bin/clipboard-keep

```bash
#!/bin/bash
# Own the X CLIPBOARD after each copy, and keep a short text history.
# Uses only xclip. X drops a selection when its owner exits.
dir=${XDG_DATA_HOME:-$HOME/.local/share}/clipboard-keep
mkdir -p "$dir/clips"
pidfile=$dir/pid
current=$dir/current
tmp=$dir/read.tmp
err=$dir/read.err
max=50

if [[ -f $pidfile ]] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
  exit 0
fi
echo $$ >"$pidfile"
trap 'rm -f "$pidfile" "$tmp" "$err"' EXIT

own() {
  xclip -selection clipboard -loops 0 <"$1"
}

remember() {
  local last n name
  cp "$tmp" "$current"
  last=$(ls -1 "$dir/clips" 2>/dev/null | sort | tail -1)
  if [[ -n $last ]] && cmp -s "$tmp" "$dir/clips/$last"; then
    own "$current"
    return
  fi
  n=$((10#${last:-0} + 1))
  printf -v name '%06d' "$n"
  cp "$tmp" "$dir/clips/$name"
  ls -1 "$dir/clips" | sort | head -n "-$max" | while read -r old; do
    rm -f "$dir/clips/$old"
  done
  own "$current"
}

[[ -s $current ]] && own "$current"

while true; do
  if xclip -o -selection clipboard -t UTF8_STRING >"$tmp" 2>"$err"; then
    if [[ -s $tmp && $(wc -c <"$tmp") -le 512000 ]] && ! cmp -s "$tmp" "$current"; then
      remember
    fi
  elif grep -q "no owner" "$err" && [[ -s $current ]]; then
    own "$current"
  fi
  sleep 0.3
done
```
