FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
ARG VERSION=1.0.5
COPY target/docker-nexus-demo-${VERSION}.jar app.jar
CMD ["java", "-jar", "app.jar"]
