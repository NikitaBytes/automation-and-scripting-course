pipeline {
  agent { label 'ansible-agent' }
  options { timestamps() }

  stages {
    stage('Checkout repository') {
      steps {
        checkout scm
      }
    }

    stage('Build artifact') {
      steps {
        dir('lab05/php-app') {
          sh '''
            rm -f artifact.tar.gz
            tar -czf artifact.tar.gz .
            ls -lh artifact.tar.gz
          '''
        }
      }
    }

    stage('Deploy via Ansible') {
      steps {
        dir('lab05/ansible') {
          sh '''
            cp ../php-app/artifact.tar.gz ./artifact.tar.gz
            ansible-playbook -i hosts.ini deploy_php.yml -vv
          '''
        }
      }
    }
  }

  post {
    always {
      echo 'PHP deploy pipeline completed.'
    }
  }
}