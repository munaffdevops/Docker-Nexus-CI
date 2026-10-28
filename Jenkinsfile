
pipeline {
    agent any

    tools {
        jdk 'java17'
        maven 'Default Maven'
    }

    environment {
        NEXUS_URL = 'http://local-nexus:8081'
        IMAGE = 'docker-nexus-demo'
        VERSION = '1.0.5'
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
                    sh '''
                        set +x
                        python3 - <<'PY'
import os
from xml.sax.saxutils import escape

username = escape(os.environ["NX_USER"])
password = escape(os.environ["NX_PASS"])

with open("settings.xml", "w") as f:
    f.write("""<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0">
  <servers>
    <server>
      <id>nexus-releases</id>
      <username>""" + username + """</username>
      <password>""" + password + """</password>
    </server>
  </servers>
</settings>
""")
PY
                        mvn -s settings.xml deploy:deploy-file \
                          -DgroupId=com.devops \
                          -DartifactId=docker-nexus-demo \
                          -Dversion="$VERSION" \
                          -Dpackaging=jar \
                          -Dfile="target/docker-nexus-demo-${VERSION}.jar" \
                          -DrepositoryId=nexus-releases \
                          -Durl="${NEXUS_URL}/repository/maven-releases/" \
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
