pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                echo 'Code checked out from GitHub'
            }
        }

        stage('Verify Tools') {
            steps {
                bat 'git --version'
                bat 'java -version'
                bat 'sf --version'
            }
        }
        
        stage('Verify Salesforce CLI') {
             steps {
             bat 'where sf'
             bat 'sf --version'
          }
       }  

    }
}
