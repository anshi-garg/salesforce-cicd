
pipeline {
    agent any

    options {
        timestamps()
        skipDefaultCheckout(false)
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Check Salesforce CLI and SGD') {
            steps {
                bat 'sf --version'

                bat '''
                    sf plugins

                    sf plugins | findstr /I "sfdx-git-delta"
                    if errorlevel 1 (
                        echo ERROR: sfdx-git-delta plugin is not installed.
                        exit /b 1
                    )

                    sf sgd source delta --help
                '''
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

                        if errorlevel 1 exit /b 1
                    '''
                }
            }
        }

        stage('Verify Salesforce Dev Connection') {
            steps {
                bat '''
                    sf org display --target-org sf-dev-jenkins
                    if errorlevel 1 exit /b 1
                '''
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

                        if errorlevel 1 exit /b 1
                    '''
                }
            }
        }

        stage('Verify Salesforce Test Connection') {
            steps {
                bat '''
                    sf org display --target-org sf-test-jenkins
                    if errorlevel 1 exit /b 1
                '''
            }
        }

        stage('Generate Salesforce Delta') {
            when {
                changeRequest()
            }

            steps {
                bat '''
                    echo ========================================
                    echo PR source branch: %CHANGE_BRANCH%
                    echo PR target branch: %CHANGE_TARGET%
                    echo ========================================

                    git fetch origin "+refs/heads/%CHANGE_TARGET%:refs/remotes/origin/%CHANGE_TARGET%"
                    if errorlevel 1 exit /b 1

                    if exist "delta" rmdir /S /Q "delta"

                    mkdir "delta"
                    if errorlevel 1 exit /b 1

                    sf sgd source delta ^
                      --from "origin/%CHANGE_TARGET%" ^
                      --to "HEAD" ^
                      --output-dir "delta" ^
                      --generate-delta

                    if errorlevel 1 exit /b 1

                    echo.
                    echo ========================================
                    echo Generated SGD files
                    echo ========================================

                    dir /S /B delta

                    if not exist "delta\\package\\package.xml" (
                        echo ERROR: delta\\package\\package.xml was not generated.
                        echo Review the SGD output above.
                        exit /b 1
                    )

                    echo.
                    echo ========================================
                    echo Generated package.xml
                    echo ========================================

                    type "delta\\package\\package.xml"
                '''
            }
        }

        stage('Validate Salesforce Changes') {
            when {
                changeRequest()
            }

            steps {
                bat '''
                    echo Validating Salesforce metadata against Test org...

                    sf project deploy validate ^
                      --manifest "delta\\package\\package.xml" ^
                      --target-org sf-test-jenkins ^
                      --test-level RunLocalTests ^
                      --wait 60

                    if errorlevel 1 exit /b 1
                '''
            }
        }
    }

    post {
        always {
            echo 'Salesforce CI pipeline completed. Review the stage results and console output.'
        }

        success {
            echo 'Pipeline succeeded.'
        }

        failure {
            echo 'Pipeline failed. Review the failed stage in the Jenkins console output.'
        }
    }
}
