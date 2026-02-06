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
# 极致压缩配置：针对 2核4GB 服务器，最多5个并发
# -Xms: 初始堆内存, -Xmx: 最大堆内存（256MB 是 Spring Boot 应用的最低可行值）
# -XX:+UseSerialGC: 串行GC（内存占用最小）
# -XX:MaxMetaspaceSize: 限制元空间, -XX:CompressedClassSpaceSize: 压缩类空间
# -XX:+UseCompressedOops: 压缩对象指针, -XX:+UseCompressedClassPointers: 压缩类指针
# -XX:MaxDirectMemorySize: 限制直接内存, -Xss: 线程栈大小
CMD ["java", "-Xms128m", "-Xmx256m", "-XX:MaxMetaspaceSize=96m", "-XX:CompressedClassSpaceSize=48m", "-XX:MaxDirectMemorySize=64m", "-Xss256k", "-XX:+UseSerialGC", "-XX:+UseCompressedOops", "-XX:+UseCompressedClassPointers", "-XX:+TieredCompilation", "-XX:TieredStopAtLevel=1", "-Djava.awt.headless=true", "-jar", "app.jar"]
