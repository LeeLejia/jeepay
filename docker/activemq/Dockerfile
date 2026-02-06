FROM bellsoft/liberica-openjdk-alpine:13

ENV ACTIVEMQ_VERSION 5.19.1
ENV ACTIVEMQ apache-activemq-$ACTIVEMQ_VERSION
ENV ACTIVEMQ_HOME /opt/activemq

# 使用 5.19.1（国内镜像有），5.16.4 仅在 archive.apache.org 且国内常超时
# 可选: mirrors.aliyun.com | mirrors.tuna.tsinghua.edu.cn
ARG ACTIVEMQ_MIRROR=https://mirrors.aliyun.com/apache/activemq
RUN apk add --update curl && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /opt && \
    curl -fsSL ${ACTIVEMQ_MIRROR}/${ACTIVEMQ_VERSION}/${ACTIVEMQ}-bin.tar.gz -o /tmp/activemq.tar.gz && \
    tar -xzf /tmp/activemq.tar.gz -C /opt && rm /tmp/activemq.tar.gz && \
    ln -s /opt/$ACTIVEMQ $ACTIVEMQ_HOME && \
    addgroup -S activemq && \
    adduser -S -H -G activemq -h $ACTIVEMQ_HOME activemq && \
    chown -R activemq:activemq /opt/$ACTIVEMQ && \
    chown -h activemq:activemq $ACTIVEMQ_HOME

COPY ./activemq.xml $ACTIVEMQ_HOME/conf/activemq.xml

EXPOSE 1883 5672 8161 61613 61614 61616

USER activemq
WORKDIR $ACTIVEMQ_HOME

CMD ["/bin/sh", "-c", "bin/activemq console"]