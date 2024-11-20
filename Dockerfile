FROM --platform=linux/amd64 dart:stable-sdk AS build

WORKDIR /app
COPY pubspec.lock pubspec.lock
COPY pubspec.yaml pubspec.yaml
COPY analysis_options.yaml analysis_options.yaml
COPY bin bin
COPY lib lib
RUN mkdir -p dist
RUN dart pub get
RUN dart compile exe bin/setup_surreal.dart -o dist/setup_surreal
RUN dart compile exe bin/firehose_indexer.dart -o dist/firehose_indexer
RUN dart compile exe bin/historical_indexer.dart -o dist/historical_indexer

FROM --platform=linux/amd64 scratch  AS setup_surreal
COPY --from=build /app/dist/setup_surreal /setup_surreal
ENTRYPOINT [ "/setup_surreal" ]
ENV SURREAL_URL="ws://surreal:8000/rpc"
ENV HISTORICAL_INDEXER_IGNORE="app.bsky.feed.post,app.bsky.feed.repost,app.bsky.feed.like"

FROM --platform=linux/amd64 scratch AS firehose_indexer
COPY --from=build /app/dist/firehose_indexer /firehose_indexer
ENTRYPOINT [ "/firehose_indexer" ]
ENV SURREAL_URL="ws://surreal:8000/rpc"
ENV HISTORICAL_INDEXER_IGNORE="app.bsky.feed.post,app.bsky.feed.repost,app.bsky.feed.like"

FROM --platform=linux/amd64 scratch AS historical_indexer
COPY --from=build /app/dist/historical_indexer /historical_indexer
ENTRYPOINT [ "/historical_indexer" ]
ENV SURREAL_URL="ws://surreal:8000/rpc"
ENV HISTORICAL_INDEXER_IGNORE="app.bsky.feed.post,app.bsky.feed.repost,app.bsky.feed.like"
