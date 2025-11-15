# ===============================
# 1️⃣ BUILD STAGE — MAVEN BUILDER
# ===============================
FROM maven:3.9.6-eclipse-temurin-17 AS builder

# Set working directory
WORKDIR /app

# Copy pom.xml first (faster build using Docker cache)
COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline

# Copy the source code
COPY src ./src

# Build the WAR package
RUN mvn clean package -DskipTests


# ==========================
# 2️⃣ RUNTIME STAGE — TOMCAT
# ==========================
FROM tomcat:9.0-jdk17

# Clean default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the WAR from builder stage
COPY --from=builder /app/target/*.war /usr/local/tomcat/webapps/

# Expose Tomcat port
EXPOSE 8500

# Start Tomcat
CMD ["catalina.sh", "run"]
