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
            
            dir('lab05') {
            sh '''
                # удаляем старый артефакт, если есть
                rm -f php-app/artifact.tar.gz

                # создаём архив, находясь в lab05, а код берем из каталога php-app
                tar -czf php-app/artifact.tar.gz -C php-app .

                # выводим инфу о созданном файле
                ls -lh php-app/artifact.tar.gz
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