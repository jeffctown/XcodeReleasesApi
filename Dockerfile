# Compile Image
FROM swift:5.1.1 as builder
RUN apt-get -qq update && apt-get install -y libssl-dev zlib1g-dev \
  && rm -r /var/lib/apt/lists/*
WORKDIR /app
COPY . .
RUN mkdir -p /build/lib && cp -R /usr/lib/swift/linux/*.so* /build/lib
RUN swift build -c release && mv `swift build -c release --show-bin-path` /build/bin

# Production image
FROM ubuntu:18.04
# DEBIAN_FRONTEND=noninteractive for automatic UTC configuration in tzdata
RUN apt-get -qq update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  libatomic1 libicu60 libxml2 libcurl4 libz-dev libbsd0 tzdata \
  && rm -r /var/lib/apt/lists/*
WORKDIR /app
RUN mkdir -p /var/lib/xcodereleases/data
COPY --from=builder /build/bin/Run .
COPY --from=builder /build/lib/* /usr/lib/


# WITHOUT DOCKER COMPOSE:
#
# uncomment this
#ENTRYPOINT ./Run serve --env "prod" --hostname 0.0.0.0 --port 80
# and run these
#docker build -t xcodereleases .
#docker run -it -p 80:80 xcodereleases
