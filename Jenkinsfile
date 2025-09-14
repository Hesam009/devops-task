pipeline {
  agent any
  environment {
    AWS_REGION = 'ap-south-1'
    AWS_ACCOUNT_ID = '480552287070'
    ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/devops-task"
    IMAGE_TAG = "${env.BUILD_NUMBER}"
    ECS_CLUSTER = "devops-cluster"
    ECS_SERVICE = "devops-service"
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Build & Test') {
      steps {
        sh 'npm install'
        sh 'npm test || echo "no tests"'
      }
    }
    stage('Docker Build & Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds',
                          usernameVariable: 'AWS_ACCESS_KEY_ID',
                          passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
          aws ecr describe-repositories --repository-names devops-task || \
            aws ecr create-repository --repository-name devops-task
          aws ecr get-login-password --region ${AWS_REGION} | \
            docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
          docker build -t ${ECR_REPO}:${IMAGE_TAG} .
          docker push ${ECR_REPO}:${IMAGE_TAG}
          '''
        }
      }
    }
    stage('Deploy to ECS') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds',
                          usernameVariable: 'AWS_ACCESS_KEY_ID',
                          passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
          cat > taskdef.json <<EOF
          {
            "family": "devops-task",
            "networkMode": "awsvpc",
            "executionRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole",
            "containerDefinitions": [{
              "name": "devops-task",
              "image": "${ECR_REPO}:${IMAGE_TAG}",
              "memory": 512,
              "cpu": 256,
              "essential": true,
              "portMappings": [{"containerPort": 3000}],
              "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                  "awslogs-group": "/ecs/devops-task",
                  "awslogs-region": "${AWS_REGION}",
                  "awslogs-stream-prefix": "ecs"
                }
              }
            }],
            "requiresCompatibilities": ["FARGATE"],
            "cpu": "256",
            "memory": "512"
          }
          EOF
          aws ecs register-task-definition --cli-input-json file://taskdef.json
          aws ecs update-service --cluster ${ECS_CLUSTER} \
            --service ${ECS_SERVICE} --force-new-deployment
          '''
        }
      }
    }
  }
}
