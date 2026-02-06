# Jeepay 多模块构建 Dockerfile
# 使用方式: docker build --build-arg PLATFORM=payment --build-arg PORT=9216 -t jeepay-payment:latest .
# PLATFORM 可选: payment | manager | merchant

# ------ 构建阶段 ------
FROM maven:3.9-eclipse-temurin-17 AS builder

ARG PLATFORM=payment
ARG PORT=9216

WORKDIR /build

# 复制源码并构建
COPY . .
RUN mvn clean package -DskipTests -pl jeepay-${PLATFORM} -am -B

# ------ 运行阶段 ------
FROM eclipse-temurin:17-jre

ARG PLATFORM=payment
ARG PORT=9216

ENV LANG=C.UTF-8
ENV TZ=Asia/Shanghai

EXPOSE ${PORT}

RUN mkdir -p /workspace/logs

WORKDIR /workspace

COPY --from=builder /build/jeepay-${PLATFORM}/target/jeepay-${PLATFORM}.jar ./app.jar

# docker-compose 会挂载 application.yml 到 /workspace/application.yml
# 低资源消耗配置：针对 2核4GB 服务器，最多5个并发
# -Xms: 初始堆内存, -Xmx: 最大堆内存, -XX:+UseSerialGC: 使用串行GC（单核友好，内存占用小）
# -XX:MaxMetaspaceSize: 限制元空间大小, -XX:CompressedClassSpaceSize: 压缩类空间
CMD ["java", "-Xms128m", "-Xmx384m", "-XX:MaxMetaspaceSize=128m", "-XX:CompressedClassSpaceSize=64m", "-XX:+UseSerialGC", "-XX:+TieredCompilation", "-XX:TieredStopAtLevel=1", "-jar", "app.jar"]
