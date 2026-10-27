pipeline {
    agent any

    tools {
        jdk 'java17'
        maven 'Default Maven'
    }

    environment {
        NEXUS_URL = 'http://local-nexus:8081'
        IMAGE = 'docker-nexus-demo'
        VERSION = '1.0.3'
        REGISTRY = 'host.docker.internal:8082'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build JAR') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Upload JAR to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-credentials',
                    usernameVariable: 'NX_USER',
                    passwordVariable: 'NX_PASS'
                )]) {
                    script {
                        def xmlEscape = { s ->
                            s.replace('&', '&amp;')
                             .replace('<', '&lt;')
                             .replace('>', '&gt;')
                             .replace('"', '&quot;')
                             .replace("'", '&apos;')
                        }

                        writeFile file: 'settings.xml', text: """
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0">
  <servers>
    <server>
      <id>nexus-releases</id>
      <username>${xmlEscape(env.NX_USER)}</username>
      <password>${xmlEscape(env.NX_PASS)}</password>
    </server>
  </servers>
</settings>
"""
                    }

                    sh '''
                        mvn -s settings.xml deploy:deploy-file \
                          -DgroupId=com.devops \
                          -DartifactId=docker-nexus-demo \
                          -Dversion=${VERSION} \
                          -Dpackaging=jar \
                          -Dfile=target/docker-nexus-demo-${VERSION}.jar \
                          -DrepositoryId=nexus-releases \
                          -Durl=${NEXUS_URL}/repository/maven-releases/ \
                          -DgeneratePom=true
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${IMAGE}:${VERSION} .'
                sh 'docker tag ${IMAGE}:${VERSION} ${REGISTRY}/docker-releases/${IMAGE}:${VERSION}'
            }
        }

        stage('Push Image to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-docker-credentials',
                    usernameVariable: 'NX_DOCKER_USER',
                    passwordVariable: 'NX_DOCKER_PASS'
                )]) {
                    sh '''
                        set +x
                        printf '%s' "$NX_DOCKER_PASS" |
                          docker login "$REGISTRY" \
                            -u "$NX_DOCKER_USER" --password-stdin
                    '''
                }

                sh 'docker push ${REGISTRY}/docker-releases/${IMAGE}:${VERSION}'
            }
        }

        stage('Verify Container') {
            steps {
                sh 'docker run --rm ${REGISTRY}/docker-releases/${IMAGE}:${VERSION}'
            }
        }
    }

    post {
        always {
            sh 'rm -f settings.xml'
        }
        success {
            echo 'CI/CD PIPELINE SUCCESS!'
        }
        failure {
            echo 'Pipeline failed. Check Console Output.'
        }
    }
}