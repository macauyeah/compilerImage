podman container run -e DISPLAY=${DISPLAY} -v /tmp/.X11-unix:/tmp/.X11-unix:rw -it --entrypoint /bin/bash --rm wingzzz2003/qoderChecking the container setup and Dockerfile to confirm if the image is missing any X11 runtime configuration.

Read [](file:///home/deck/workspace/qoder/docker-compose.yaml)

Read [](file:///home/deck/workspace/qoder/Dockerfile)

## Problem

The error means your container can see `DISPLAY=:0`, but it is not authorized to connect to the host X server.

`xeyes` is trying to open the host display, but X11 uses an authorization cookie (`.Xauthority`) and your container does not have it.

---

## Why this happens

With Podman on Linux:

- `DISPLAY` alone is not enough
- .X11-unix gives socket access
- but X11 also requires the right auth credentials
- rootless containers usually run as a different user namespace, so they cannot use the host X authority by default

---

## Fix

### Option 1: Quick test with `xhost` (insecure)
On the host, run:

```bash
xhost +local:
```

Then start Podman with:

```bash
podman container run -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix:rw -it --entrypoint /bin/bash --rm MYIMAGE
```

If `xeyes` works after that, the issue was definitely X11 auth.

> Note: `xhost +local:` is insecure and only good for testing.

---

### Option 2: Proper fix with `.Xauthority`
Use the host X auth file in the container:

```bash
podman container run \
  -e DISPLAY=$DISPLAY \
  -e XAUTHORITY=/home/ubuntu/.Xauthority \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v $HOME/.Xauthority:/home/ubuntu/.Xauthority:ro \
  -it --entrypoint /bin/bash --rm MYIMAGE
```

If your container user is root, use:

```bash
  -e XAUTHORITY=/root/.Xauthority \
  -v $HOME/.Xauthority:/root/.Xauthority:ro
```

---

## Dockerfile / image notes

Your Dockerfile currently does not install X11 test apps. If you want `xeyes`, add:

```dockerfile
RUN apt-get update && apt-get install -y x11-apps
```

But the current error is not about missing `xeyes`; it is about authorization.

---

## Additional note

If your host is using Wayland, `DISPLAY=:0` implies XWayland. For full Wayland support you need a different approach, but for X11 apps the X11 socket + `.Xauthority` fix is the right path.

---

## Summary

- The problem is X11 auth, not `DISPLAY`
- Mount .X11-unix and also mount the host `~/.Xauthority`
- Set `XAUTHORITY` inside the container
- `xhost +local:` can confirm the issue quickly

If you want, I can also show the exact docker-compose.yaml changes to make X11 work in your service configuration.