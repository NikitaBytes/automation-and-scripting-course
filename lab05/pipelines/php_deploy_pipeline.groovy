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
            # удаляем старый артефакт, если есть
            rm -f artifact.tar.gz

            # создаём новый архив, но игнорируем сам файл artifact.tar.gz
            tar --exclude=artifact.tar.gz -czf artifact.tar.gz .

            # выводим информацию о созданном файле
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