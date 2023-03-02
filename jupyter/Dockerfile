FROM jupyter/all-spark-notebook:spark-3.3.0

COPY ./requirements.txt .

RUN pip install --no-cache-dir --upgrade -r requirements.txt

RUN pip install jupyter_contrib_nbextensions

RUN jupyter contrib nbextension install --user

RUN jupyter nbextension enable varInspector/main

HEALTHCHECK  --interval=15s --timeout=3s \
    CMD wget -O- --no-verbose --tries=1 http://localhost:8888/api || exit 1

# RUN apt-get update && \
#     apt-get install -y software-properties-common

# RUN add-apt-repository ppa:longsleep/golang-backports && \
#     apt-get update && \
#     apt-get install -y golang-go libzmq3-dev

# USER $NB_UID

# RUN GO111MODULE=off go get -d -u github.com/gopherdata/gophernotes

# RUN cd "$(go env GOPATH)"/src/github.com/gopherdata/gophernotes && \
#     env GO111MODULE=on go install

# RUN cd "$(go env GOPATH)"/src/github.com/gopherdata/gophernotes && \
#     mkdir -p ~/.local/share/jupyter/kernels/gophernotes && \
#     cp -r ./kernel/* ~/.local/share/jupyter/kernels/gophernotes && \
#     cd ~/.local/share/jupyter/kernels/gophernotes && \
#     sed "s|gophernotes|$(go env GOPATH)/bin/gophernotes|" < kernel.json.in > kernel.json