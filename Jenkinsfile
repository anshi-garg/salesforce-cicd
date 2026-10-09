
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Check Salesforce CLI') {
            steps {
                bat 'sf --version'
                bat 'sf plugins --help'
                bat 'sf plugins install --help'
            }
        }

        stage('Install SGD for jenkins') {
            steps {
                bat 'sf plugins install sfdx-git-delta --force'
                bat 'sf plugins'
                bat 'sf sgd source delta --help'

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

        stage('Verify Salesforce Dev Connection') {
            steps {
                bat 'sf org display --target-org sf-dev-jenkins'
            }
        }

        stage('Authenticate to Salesforce Test') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'sf-test-consumer-key',
                        variable: 'SF_TEST_CONSUMER_KEY'
                    ),
                    string(
                        credentialsId: 'sf-test-username',
                        variable: 'SF_TEST_USERNAME'
                    ),
                    file(
                        credentialsId: 'sf-jwt-private-key',
                        variable: 'SF_JWT_KEY_FILE'
                    )
                ]) {
                    bat '''
                        sf org login jwt ^
                          --client-id "%SF_TEST_CONSUMER_KEY%" ^
                          --username "%SF_TEST_USERNAME%" ^
                          --jwt-key-file "%SF_JWT_KEY_FILE%" ^
                          --instance-url https://login.salesforce.com ^
                          --alias sf-test-jenkins
                    '''
                }
            }
        }

        stage('Verify Salesforce Test Connection') {
            steps {
                bat 'sf org display --target-org sf-test-jenkins'
            }
        }
    }
}
