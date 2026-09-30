pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  environment {
    APP_NAME       = 'multi-region-app'
    AWS_ACCOUNT_ID = credentials('aws-account-id')   // "Secret text" credential
    PRIMARY_REGION = 'us-east-1'
    SECONDARY_REGION = 'ap-south-1'
    IMAGE_TAG      = "${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t ${APP_NAME}:${IMAGE_TAG} app/'
      }
    }

    stage('Smoke Test') {
      steps {
        sh '''
          docker rm -f smoke || true
          docker run -d --name smoke -p 3999:3000 ${APP_NAME}:${IMAGE_TAG}
          for i in $(seq 1 15); do
            curl -sf http://localhost:3999/health && break || sleep 2
          done
          curl -sf http://localhost:3999/health
        '''
      }
      post { always { sh 'docker rm -f smoke || true' } }
    }

    stage('Trivy Scan') {
      steps {
        // Save a full report (does not fail the build)
        sh '''
          trivy image --format table --output trivy-report.txt \
            --severity HIGH,CRITICAL --ignore-unfixed ${APP_NAME}:${IMAGE_TAG}
        '''
        // Gate: exit code 1 (build fails) if any fixable HIGH/CRITICAL vuln exists
        sh '''
          trivy image --exit-code 1 --severity HIGH,CRITICAL \
            --ignore-unfixed --no-progress ${APP_NAME}:${IMAGE_TAG}
        '''
      }
      post { always { archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true } }
    }

    stage('Push to ECR (both regions)') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds',
                          usernameVariable: 'AWS_ACCESS_KEY_ID',
                          passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            for REGION in ${PRIMARY_REGION} ${SECONDARY_REGION}; do
              REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com
              aws ecr get-login-password --region ${REGION} | \
                docker login --username AWS --password-stdin ${REGISTRY}
              docker tag ${APP_NAME}:${IMAGE_TAG} ${REGISTRY}/${APP_NAME}:${IMAGE_TAG}
              docker tag ${APP_NAME}:${IMAGE_TAG} ${REGISTRY}/${APP_NAME}:latest
              docker push ${REGISTRY}/${APP_NAME}:${IMAGE_TAG}
              docker push ${REGISTRY}/${APP_NAME}:latest
            done
          '''
        }
      }
    }

    stage('Rolling Deploy (ASG Instance Refresh)') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds',
                          usernameVariable: 'AWS_ACCESS_KEY_ID',
                          passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            for REGION in ${PRIMARY_REGION} ${SECONDARY_REGION}; do
              aws autoscaling start-instance-refresh --region ${REGION} \
                --auto-scaling-group-name ${APP_NAME}-asg-${REGION} \
                --preferences '{"MinHealthyPercentage":50,"InstanceWarmup":90}'
            done
          '''
        }
      }
    }
  }

  post {
    always  { sh 'docker image prune -f || true' }
    success { echo 'Deployed to both regions.' }
    failure { echo 'Pipeline failed - check the Trivy report / logs. Nothing was deployed past the failed stage.' }
  }
}
