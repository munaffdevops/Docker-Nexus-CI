
pipeline {
    agent any

    tools {
        jdk 'java17'
        maven 'Default Maven'
    }

    environment {
        NEXUS_URL = 'http://local-nexus:8081'
        DOCKER_REGISTRY = 'localhost:8082'
        IMAGE_NAME = 'docker-nexus-demo'
        IMAGE_TAG = '1.0.1'
        NEXUS_CREDENTIALS = 'nexus-credentials'
        DOCKER_CREDENTIALS = 'nexus-docker-credentials'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Using the current Jenkins workspace source code'
            }
        }

        stage('Build JAR') {
            steps {
                bat 'mvn clean package'
            }
        }

        stage('Upload JAR to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${NEXUS_CREDENTIALS}",
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    bat '''
                        mvn deploy:deploy-file ^
                        "-DgroupId=com.devops" ^
                        "-DartifactId=docker-nexus-demo" ^
                        "-Dversion=1.0.1" ^
                        "-Dpackaging=jar" ^
                        "-Dfile=target\\docker-nexus-demo-1.0.1.jar" ^
                        "-DrepositoryId=nexus-releases" ^
                        "-Durl=http://local-nexus:8081/repository/maven-releases/" ^
                        "-DgeneratePom=true" ^
                        "-DrepositoryLayout=default"
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                bat 'docker build -t docker-nexus-demo:1.0.1 .'
                bat 'docker tag docker-nexus-demo:1.0.1 localhost:8082/docker-releases/docker-nexus-demo:1.0.1'
            }
        }

        stage('Push Image to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDENTIALS}",
                    usernameVariable: 'REGISTRY_USER',
                    passwordVariable: 'REGISTRY_PASS'
                )]) {
                    bat '''
                        docker login %DOCKER_REGISTRY% -u "%REGISTRY_USER%" --password-stdin < NUL
                    '''
                }
                bat 'docker push localhost:8082/docker-releases/docker-nexus-demo:1.0.1'
            }
        }

        stage('Verify Container') {
            steps {
                bat 'docker run --rm localhost:8082/docker-releases/docker-nexus-demo:1.0.1'
            }
        }
    }

    post {
        success {
            echo 'CI/CD PIPELINE SUCCESS!'
        }
        failure {
            echo 'Pipeline failed. Check Console Output.'
        }
    }
}
