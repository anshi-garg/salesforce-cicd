
pipeline {
    agent any

    stages {

        // 1. Checkout the PR code
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // 2. Check Salesforce CLI and SGD
        stage('Check Salesforce CLI and SGD') {
            steps {
                bat 'sf --version'
                bat 'sf plugins'

                // Install SGD only if it is not already installed
                bat '''
                    sf plugins | findstr /I "sfdx-git-delta"
                    if errorlevel 1 (
                        sf plugins trust allowlist add --name sfdx-git-delta
                        sf plugins install sfdx-git-delta
                    )
                    sf sgd source delta --help
                '''
            }
        }

        // 3. Authenticate to Salesforce Dev
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

        // 4. Authenticate to Salesforce Test
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

        // 5. Generate delta package for pull requests
        stage('Generate Salesforce Delta') {
            when {
                changeRequest()
            }
            steps {
                bat '''
                    echo PR source branch: %CHANGE_BRANCH%
                    echo PR target branch: %CHANGE_TARGET%

                    git fetch origin "+refs/heads/%CHANGE_TARGET%:refs/remotes/origin/%CHANGE_TARGET%"

                    if exist "delta" rmdir /S /Q "delta"

                    sf sgd source delta ^
                      --from "origin/%CHANGE_TARGET%" ^
                      --to "HEAD" ^
                      --output-dir "delta" ^
                      --generate-delta

                    if errorlevel 1 exit /b 1

                    if not exist "delta\\package\\package.xml" (
                        echo ERROR: SGD did not generate delta\\package\\package.xml
                        exit /b 1
                    )

                    echo Generated Salesforce package.xml:
                    type "delta\\package\\package.xml"
                '''
            }
        }

        // 6. Validate PR changes without deploying them
        stage('Validate Salesforce Changes') {
            when {
                changeRequest()
            }
            steps {
                bat '''
                    sf project deploy validate ^
                      --manifest "delta\\package\\package.xml" ^
                      --target-org sf-test-jenkins ^
                      --test-level RunLocalTests ^
                      --wait 60
                '''
            }
        }
    }

    post {
        always {
            echo 'Salesforce CI pipeline completed. Check the stage results above.'
        }
        success {
            echo 'Pipeline succeeded.'
        }
        failure {
            echo 'Pipeline failed. Review the Jenkins console output.'
        }
    }
}
