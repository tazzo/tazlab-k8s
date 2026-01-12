docker build -f .devcontainer/Dockerfile -t tazzo/tazlab.net:devpod .
docker push tazzo/tazlab.net:devpod
devpod delete tazlab-k8s && devpod up . --ide none
