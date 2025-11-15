pipeline {
    agent any

    tools {
        jdk 'JDK'
        maven 'MAVEN'
    }

    environment {
        JAVA_HOME = tool name: 'JDK', type: 'jdk'
        PATH = "${JAVA_HOME}/bin:${env.PATH}"
        // Define Docker image with build number to avoid conflicts
        DOCKER_IMAGE = "udaysairam/java-webapp:${env.BUILD_NUMBER}"
        MAVEN_SETTINGS = "temp-settings.xml"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/uday79936/Java-Web-Calculator-App.git'
            }
        }

        stage('Build with Maven') {
            steps {
                echo "Running Maven build..."
                sh 'mvn clean verify -B'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "Running SonarQube analysis..."
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh 'mvn sonar:sonar -B -Dsonar.projectKey=java-webapp-region -Dsonar.host.url=http://54.196.254.229:9000 -Dsonar.login=$SONAR_TOKEN'
                }
            }
        }

        stage('Deploy to Nexus') {
            steps {
                echo "Deploying artifact to Nexus..."
                writeFile file: "${MAVEN_SETTINGS}", text: """
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.2.0 https://maven.apache.org/xsd/settings-1.2.0.xsd">
  <servers>
    <server>
      <id>maven-snapshots</id>
      <username>admin</username>
      <password>admin123</password>
    </server>
  </servers>
</settings>
"""
                sh 'mvn deploy -B -s ${MAVEN_SETTINGS} -DaltDeploymentRepository=maven-snapshots::default::http://54.196.254.229:8081/repository/maven-snapshots/'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${DOCKER_IMAGE}"
                sh """
                    docker build -t ${DOCKER_IMAGE} .
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo "Pushing Docker image to Docker Hub: ${DOCKER_IMAGE}"
                withCredentials([usernamePassword(credentialsId: 'docker_hub', usernameVariable: 'DOCKER_HUB_USR', passwordVariable: 'DOCKER_HUB_PSW')]) {
                    sh """
                        echo \$DOCKER_HUB_PSW | docker login -u \$DOCKER_HUB_USR --password-stdin
                        docker push ${DOCKER_IMAGE}
                    """
                }
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                echo "Deploying Docker container for Tomcat..."
                sh """
                    docker stop TOMCAT || true
                    docker rm TOMCAT || true
                    docker run -d --name TOMCAT -p 8500:8080 ${DOCKER_IMAGE}
                """
            }
        }
    }

    post {
        always {
            echo "Pipeline finished."
            sh 'rm -f ${MAVEN_SETTINGS}'
        }
        success {
            echo "Pipeline succeeded! All steps completed."
        }
        failure {
            echo "Pipeline failed! Check logs for details."
        }
    }
}
