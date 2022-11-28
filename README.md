To start all services, make sure you have [Docker](https://www.docker.com/products/docker-desktop/) installed and run:
```
$ docker compose up
```

To restart the worker, i.e. after a code change:
```
$ docker compose restart worker
```

To start a console:
```
$ docker compose run --rm web bin/rails console
```

If you run docker with a VM (e.g. Docker Desktop for Mac) we recommend you allocate at least 2GB Memory
