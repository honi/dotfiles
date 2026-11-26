# Webcam diagnostics.
#
# v4l-utils provides v4l2-ctl, which lists a camera's formats, resolutions and
# frame rates, reads and sets its controls (zoom, focus, exposure) and tests
# streaming, without a video-call app.

apt_install v4l-utils

verify_installed v4l-utils
verify "v4l2-ctl available" command -v v4l2-ctl
