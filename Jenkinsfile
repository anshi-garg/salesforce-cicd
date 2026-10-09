
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Tools') {
            steps {
                bat 'git --version'
                bat 'java -version'
                bat 'sf --version'
                bat 'where sf'
            }
        }

        stage('Authenticate to Salesforce Dev') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'sf-consumer-key',
                        variable: 'SF_CONSUMER_KEY'
                    ),
                    string(
                        credentialsId: 'sf-dev-username',
                        variable: 'SF_USERNAME'
                    ),
                    file(
                        credentialsId: 'sf-jwt-private-key',
                        variable: 'SF_JWT_KEY_FILE'
                    )
                ]) {
                    bat '''
                        sf org login jwt ^
                          --client-id "%SF_CONSUMER_KEY%" ^
                          --username "%SF_USERNAME%" ^
                          --jwt-key-file "%SF_JWT_KEY_FILE%" ^
                          --instance-url https://login.salesforce.com ^
                          --alias sf-dev-jenkins
                    '''
                }
            }
        }
    }
}
