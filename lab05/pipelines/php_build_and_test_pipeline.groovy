pipeline {
  agent { label 'php-agent' }
  options { timestamps() }

  stages {
    stage('Checkout repository') {
      steps {
        checkout scm
      }
    }

    stage('Install dependencies') {
        steps {
            dir('lab05/php-app') {
                sh '''
                    php -v
                    composer --version || true

                    composer install --no-interaction --no-progress
                '''
            }
        }
    }

    stage('Run tests') {
      steps {
        dir('lab05/php-app') {
          sh '''
            if [ -f vendor/bin/phpunit ]; then
              vendor/bin/phpunit --colors=always
            else
              echo "No PHPUnit found — skipping."
            fi
          '''
        }
      }
    }
  }

  post {
    always {
      echo 'PHP build+test pipeline completed.'
    }
  }
}