pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        ECR_REPO = "009160029390.dkr.ecr.ap-south-1.amazonaws.com/satyajit-coursevita-repo"
        ECR_IMAGE = "${ECR_REPO}:latest"

        DOCKER_HUB_USER = "satya44jit"
        DOCKERHUB_IMAGE = "${DOCKER_HUB_USER}/myapp:latest"
        // You must create this Jenkins credential with your Docker Hub password/token
        DOCKER_HUB_PASS = credentials('dockerhub-credentials') 

        REMOTE_HOST = "ec2-user@13.201.124.43"
        REMOTE_APP_NAME = "httpd-app"
    }

    stages {
        stage('Checkout from GitHub') {
            steps {
                git branch: 'main', url: 'https://github.com/chinabudhi123/ECR-DOCKERHUB-Pipeline.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t $DOCKERHUB_IMAGE ."
                sh "docker tag $DOCKERHUB_IMAGE $ECR_IMAGE"
            }
        }

        stage('Login to Docker Hub') {
            steps {
                sh """
                    echo $DOCKER_HUB_PASS | docker login --username $DOCKER_HUB_USER --password-stdin
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                sh "docker push $DOCKERHUB_IMAGE"
            }
        }

        stage('Login to ECR') {
            steps {
                sh """
                    aws ecr get-login-password --region $AWS_REGION | \
                    docker login --username AWS --password-stdin $ECR_REPO
                """
            }
        }

        stage('Push to ECR') {
            steps {
                sh "docker push $ECR_IMAGE"
            }
        }

        stage('Manual Approval') {
            steps {
                input message: "Approve deployment to EC2 at 13.201.124.43?", ok: "Deploy"
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(credentials: ['ec2-access']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no $REMOTE_HOST '
                            # Docker login to ECR
                            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

                            # Docker login to Docker Hub
                            echo $DOCKER_HUB_PASS | docker login --username $DOCKER_HUB_USER --password-stdin

                            # Pull latest images
                            docker pull $ECR_IMAGE
                            docker pull $DOCKERHUB_IMAGE

                            # Stop & remove existing containers if any
                            docker stop $REMOTE_APP_NAME || true
                            docker rm $REMOTE_APP_NAME || true
                            docker stop ${REMOTE_APP_NAME}_8080 || true
                            docker rm ${REMOTE_APP_NAME}_8080 || true

                            # Run Docker Hub image on port 80 (host:80 -> container:80)
                            docker run -d --name $REMOTE_APP_NAME -p 80:80 $DOCKERHUB_IMAGE

                            # Run ECR image on port 8080 (host:8080 -> container:80)
                            docker run -d --name ${REMOTE_APP_NAME}_8080 -p 8080:80 $ECR_IMAGE
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment Successful! Both containers running on ports 80 and 8080.'
        }
        failure {
            echo '❌ Deployment Failed! Check logs for details.'
        }
    }
}

