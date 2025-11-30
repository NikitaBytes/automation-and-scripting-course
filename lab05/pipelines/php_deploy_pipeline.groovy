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
            set -e

            # удаляем старый артефакт, если есть
            rm -f artifact.tar.gz

            # создаём архив из php-app, но сам файл лежит в lab05/
            tar -czf artifact.tar.gz -C php-app .

            # проверяем, что файл реально создан
            ls -lh artifact.tar.gz
        '''
        }
    }
    }

    stage('Deploy via Ansible') {
        steps {
            dir('lab05/ansible') {
            sh '''
                set -e

                # копируем артефакт из lab05/ в текущую директорию (ansible/)
                cp ../artifact.tar.gz ./artifact.tar.gz

                # устанавливаем правильные права на приватный ключ
                chmod 600 test_server_ansible_key

                # запускаем Ansible-плейбук деплоя
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