pipeline {
  agent { label 'ansible-agent' }
  options { timestamps() }

  stages {
    stage('Checkout repository') {
      steps {
        checkout scm
      }
    }

    stage('Run Ansible Playbook: setup_test_server') {
      steps {
        dir('lab05/ansible') {
          sh '''
            echo "Inventory:"
            cat hosts.ini
            ansible --version
            ansible-playbook -i hosts.ini setup_test_server.yml -vv
          '''
        }
      }
    }
  }

  post {
    always {
      echo 'Ansible setup pipeline completed.'
    }
  }
}