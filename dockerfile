FROM amazoncorretto:8-alpine3.17-jre
RUN apk add --no-cache fontconfig ttf-dejavu
WORKDIR /app
COPY app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]