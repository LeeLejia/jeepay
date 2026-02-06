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
CMD ["java", "-jar", "app.jar"]
