FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    pandoc \
    texlive-xetex \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-pictures \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /work

COPY . /work/daggerheart-publish

RUN chmod +x /work/daggerheart-publish/scripts/build.sh /work/daggerheart-publish/scripts/docker-build.sh

ENTRYPOINT ["/bin/bash"]
