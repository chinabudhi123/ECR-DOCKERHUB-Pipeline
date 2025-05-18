pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        ECR_REPO = "009160029390.dkr.ecr.ap-south-1.amazonaws.com/satyajit-coursevita-repo"
        DOCKERHUB_REPO = "satya44jit/satyajit-coursevita-repo"
        IMAGE_TAG = "latest"
        REMOTE_HOST = "ec2-user@13.235.99.91"
        REMOTE_APP_NAME = "httpd-app"
    }

    parameters {
        choice(name: 'REGISTRY', choices: ['ECR', 'DockerHub', 'Both'], description: 'Select where to push the image')
    }

    stages {
        stage('Checkout from GitHub') {
            steps {
                git branch: 'main', url: 'https://github.com/chinabudhi123/ECR-DOCKERHUB-Pipeline.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def imageNameList = []
                    if (params.REGISTRY == 'ECR' || params.REGISTRY == 'Both') {
                        imageNameList.add("${ECR_REPO}:${IMAGE_TAG}")
                    }
                    if (params.REGISTRY == 'DockerHub' || params.REGISTRY == 'Both') {
                        imageNameList.add("${DOCKERHUB_REPO}:${IMAGE_TAG}")
                    }
                    // Build once locally
                    sh "docker build -t ${REMOTE_APP_NAME}:${IMAGE_TAG} ."
                    // Tag for all targets
                    for (img in imageNameList) {
                        sh "docker tag ${REMOTE_APP_NAME}:${IMAGE_TAG} ${img}"
                    }
                }
            }
        }

        stage('Login to Registries') {
            steps {
                script {
                    if (params.REGISTRY == 'ECR' || params.REGISTRY == 'Both') {
                        sh """
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                        """
                    }
                    if (params.REGISTRY == 'DockerHub' || params.REGISTRY == 'Both') {
                        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
                            sh "echo $DOCKERHUB_PASS | docker login --username $DOCKERHUB_USER --password-stdin"
                        }
                    }
                }
            }
        }

        stage('Push Images') {
            steps {
                script {
                    if (params.REGISTRY == 'ECR' || params.REGISTRY == 'Both') {
                        sh "docker push ${ECR_REPO}:${IMAGE_TAG}"
                    }
                    if (params.REGISTRY == 'DockerHub' || params.REGISTRY == 'Both') {
                        sh "docker push ${DOCKERHUB_REPO}:${IMAGE_TAG}"
                    }
                }
            }
        }

        stage('Manual Approval') {
            steps {
                input message: "Approve deployment to EC2 at ${REMOTE_HOST}?", ok: "Deploy"
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(credentials: ['ec2-access']) {
                    script {
                        def imagesToUse = []
                        if (params.REGISTRY == 'ECR' || params.REGISTRY == 'Both') {
                            imagesToUse.add("${ECR_REPO}:${IMAGE_TAG}")
                        }
                        if (params.REGISTRY == 'DockerHub' || params.REGISTRY == 'Both') {
                            imagesToUse.add("${DOCKERHUB_REPO}:${IMAGE_TAG}")
                        }
                        def deployImage = imagesToUse.size() > 0 ? imagesToUse[0] : "${ECR_REPO}:${IMAGE_TAG}"

                        sh """
                            ssh -o StrictHostKeyChecking=no $REMOTE_HOST '
                                # Login to registries
                                ${params.REGISTRY == "ECR" || params.REGISTRY == "Both" ? "aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO" : ""}
                                
                                ${params.REGISTRY == "DockerHub" || params.REGISTRY == "Both" ? "echo \$DOCKERHUB_PASS | docker login --username \$DOCKERHUB_USER --password-stdin" : ""}
                                
                                # Pull image
                                docker pull ${deployImage}

                                # Stop and remove old containers (port 80 and 8080)
                                docker stop $REMOTE_APP_NAME || true
                                docker rm $REMOTE_APP_NAME || true
                                docker stop ${REMOTE_APP_NAME}-8080 || true
                                docker rm ${REMOTE_APP_NAME}-8080 || true

                                # Run two containers on ports 80 and 8080
                                docker run -d --name $REMOTE_APP_NAME -p 80:80 ${deployImage}
                                docker run -d --name ${REMOTE_APP_NAME}-8080 -p 8080:80 ${deployImage}
                            '
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment Successful!'
        }
        failure {
            echo '❌ Deployment Failed!'
        }
    }
}

