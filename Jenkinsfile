pipeline {
    agent any

    tools {
        jdk 'jdk17'
        maven 'maven3'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', credentialsId: 'git-cred', url: 'https://github.com/Vignesh72-dev/Blogging-app.git'
            }
        }
        stage('compile') {
            steps {
                sh "mvn compile"
            }
        }

        stage ('Unit Test') {
            steps {
                sh "mvn test"
            }
        }

        stage ('Trivy FS Scan') {
            steps {
                sh 'trivy fs --format table -o trivy-report.html .'
            }
        }

        stage ('Sonarqube Analysis') {
            steps {
                withSonarQubeEnv(installationName: 'SonarQube', credentialsId: 'sonar-token') {
                    sh "$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=MyApp -Dsonar.projectKey=MyApp"
              
                }
            }
        }
        
        stage ('Quality Gate') {
            steps {
                waitForQualityGate abortPipeline: false
            }
        }
        
        stage ('Build JAR') {
            steps {
                sh "mvn package"
            }
        }
        
        stage ('Deploy to Nexus') {
            steps {
                withMaven(globalMavenSettingsConfig: 'global-settings') {
                    sh "mvn deploy"
                }
            }
        }
        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred') {
                        sh "docker build -t vigneshnataraj/myapp:${BUILD_NUMBER} ."
                        sh "docker push vigneshnataraj/myapp:${BUILD_NUMBER}"
                    }
                }
            }
        }

        stage ('Trivy Image Scan') {
            steps { sh "trivy image vigneshnataraj/myapp:${BUILD_NUMBER} > trivy-image-report.txt" }
        }

        stage ('Deploy to Kubernetes') {
            steps {
                withKubeConfig(credentialsId: 'k8-cred', namespace: 'webapps', serverUrl: 'https://19B17EAAA5E9C98D506F5924D0E56C61.gr7.ap-south-1.eks.amazonaws.com') {
                    sh "kubectl apply -f kubernetes/deployment.yaml -n webapps"
                }

            }
        }

        stage ('verify Deployment') {
            steps {
                withKubeConfig(credentialsId: 'k8-cred', namespace: 'webapps', serverUrl: 'https://19B17EAAA5E9C98D506F5924D0E56C61.gr7.ap-south-1.eks.amazonaws.com') {
                    sh "kubectl get pods -n webapps"
                    sh "kubectl get svc -n webapps"
                }
            }
        }
    }
    
    post {
        always {
            emailext (
                subject: "Pipeline '${BUILD_NUMBER}' #${BUILD_NUMBER} - ${currentBuild.currentResult}",
                body: "Check console output at ${BUILD_NUMBER}",
                to: 'natarajvicky72@gmail.com'
            )
        }
    }

}