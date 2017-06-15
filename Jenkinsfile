#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
  } 

  stages {
    stage('Build Image') {
      steps {
        sh './build.sh'
      }
    }

    stage('Build deb') {
      steps {
        sh './package.sh'
      }
    }

    stage('Test') {
      steps {
        sh './test.sh'
        
        junit 'spec/reports/*.xml, features/reports/**/*.xml, scaling_features/reports/**/*.xml, reports/*.xml'
      }
    }

    stage('Publish deb'){
      steps {
        sh './publish.sh'
      }
    }

    stage('Publish website') {
      steps {
        when {
          branch 'aws-website_170613' // XXX: change to master before merging
        }
        sh 'summon ./website.sh'
      }
    }
  }

  post {
    failure {
      slackSend(color: 'danger', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} FAILURE (<${env.BUILD_URL}|Open>)")
    }
    unstable {
      slackSend(color: 'warning', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} UNSTABLE (<${env.BUILD_URL}|Open>)")
    }
  }
}

