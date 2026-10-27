FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY target/docker-nexus-demo-1.0.3.jar app.jar
CMD ["java", "-jar", "app.jar"]