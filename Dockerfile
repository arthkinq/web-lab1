# Собираем наш сервер
FROM gradle:8.10-jdk17 AS build
COPY --chown=gradle:gradle .. /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle jar --no-daemon
#Запускаем
FROM eclipse-temurin:17-jre
EXPOSE 7777
RUN mkdir /app
WORKDIR /app
COPY --from=build /home/gradle/src/build/libs/*.jar /app/app.jar
ENTRYPOINT ["java", "-DFCGI_PORT=7777", "-jar", "app.jar"]