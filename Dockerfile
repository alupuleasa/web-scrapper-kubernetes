FROM golang:latest AS build-stage

COPY . /opt/web-scrapper
WORKDIR /opt/web-scrapper

ENV GO111MODULE on
RUN apk add --update make

# build
# RUN go build . -o web-scrapper
RUN make build

# deploy
FROM alpine:latest

RUN apk add --no-cache tzdata

WORKDIR /opt/web-scrapper
COPY --from=build-stage /opt/web-scrapper/web-scrapper  ./web-scrapper
COPY --from=build-stage /opt/web-scrapper/docroot       ./docroot

ENTRYPOINT [ "/opt/web-scrapper/web-scrapper" ]
CMD [ "run" ]