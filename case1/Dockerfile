# Stage 1: Build the application using Maven
FROM maven:3.9.3-amazoncorretto-17 AS builder

WORKDIR /app

# Copy the pom.xml and src directory
COPY pom.xml .
COPY src ./src

# Build the application and skip tests
RUN mvn clean package -DskipTests

# Stage 2: Create a lightweight image to run the application
FROM amazoncorretto:17-alpine

WORKDIR /app

# Copy the JAR file from the builder stage
COPY --from=builder /app/target/*.jar app.jar

# Create a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose the application's port
EXPOSE 8000

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
