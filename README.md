## Docker build command 
```
docker build --build-arg USER=$(id -nu) --build-arg UID=$(id -u) --build-arg GID=$(id -g) --tag qt-builder/qt-builder:1.0 .
```
## Run image
```
docker run --privileged -it -v $(pwd):/home/$USER/build-out qt-builder/qt-builder:1.0
or to get inside shell
docker run --privileged -it -v $(pwd):/home/$USER/build-out qt-builder/qt-builder:1.0 bash
```

