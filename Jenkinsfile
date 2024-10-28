#!/usr/bin/env groovy
def DOCKER_IMAGE_TYPE = null

pipeline {
  
  agent { 
     dockerfile {
       filename 'Dockerfile'
       dir 'docker/'
       args env.DOCKER_ARGS
       additionalBuildArgs "--build-arg DOCKER_IMAGE_TYPE=default"
     }
  }

  triggers {
    cron('0 1 * * 6')
    // upstream(upstreamProjects: 'kieker-dev/master', threshold: hudson.model.Result.SUCCESS)
  }

  environment {
    KEYSTORE = credentials('kieker-irl-key')
    UPDATE_SITE_URL = "sftp://repo@repo.se.internal/moobench"
    DOCKER_ARGS = ''
    BATCH_MODE = "yes"
  }

  options {
    buildDiscarder logRotator(artifactNumToKeepStr: '10')
    timeout(time: 168, unit: 'HOURS') 
    retry(1)
    parallelsAlwaysFailFast()
  }
  stages {
    stage('Choose Image') {
       when {
         beforeAgent true
       }
       steps {
          script {
             DOCKER_IMAGE_TYPE = sh(script: 'grep DOCKER_IMAGE common-functions.sh |cut -d \\#  -f1 |awk -F"=" "{print \\$2}"', returnStdout: true)
          }
          sh "echo DOCKER_IMAGE_TYPE = ${DOCKER_IMAGE_TYPE}"
       }
    }

    stage('Initial Cleanup') {
       steps {
          sh './gradlew clean'
       }
    }

    stage('Compile') {
       steps {
          sh './setup.sh'
       }
    }

    stage('Run Benchmark') {
       steps {
          catchError {
             sh './frameworks/Kieker-python/benchmark.sh'
             sh 'cp frameworks/Kieker-python/results-Kieker-python/results.yaml Kieker-python-results.yaml'
          }
          
          catchError {
             sh './frameworks/Kieker-java/benchmark.sh'
             sh 'cp frameworks/Kieker-java/results-Kieker-java/results.yaml Kieker-java-results.yaml'
          }
          
          catchError {
             sh './frameworks/Cloudprofiler-java/benchmark.sh'
             sh 'cp frameworks/Cloudprofiler-java/results-Cloudprofiler-java/results.yaml Cloudprofiler-java-results.yaml'
          }

          catchError {
             sh './frameworks/OpenTelemetry-java/benchmark.sh'
             sh 'cp frameworks/OpenTelemetry-java/results-OpenTelemetry-java/results.yaml OpenTelemetry-java-results.yaml'
          }
          
          catchError {
             sh './frameworks/inspectIT-java/benchmark.sh'
             sh 'cp frameworks/inspectIT-java/results-inspectIT-java/results.yaml inspectIT-java-results.yaml'
          }
          
          stash includes: '*-results.yaml', name: 'yaml'
       }
    }
    
    stage('Upload') {
       steps {
          sshagent(credentials: ['kieker-irl-key']) {
             unstash 'yaml'
             sh "./upload.sh ${KEYSTORE} ${UPDATE_SITE_URL}"
          }
       }
       post {
         cleanup {
           deleteDir()
           cleanWs()
         }
       }
    }
  }
}
