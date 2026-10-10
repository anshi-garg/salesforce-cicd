
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
                bat '''
                    sf --version
                    if errorlevel 1 exit /b 1

                    sf plugins

                    sf plugins | findstr /I "sfdx-git-delta"
                    if errorlevel 1 (
                        echo ERROR: sfdx-git-delta is not installed.
                        exit /b 1
                    )

                    sf sgd source delta --help
                    if errorlevel 1 exit /b 1
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

        stage('Verify Salesforce Dev') {
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

        stage('Verify Salesforce Test') {
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

                    echo Generating Salesforce delta...

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
                        echo Check the SGD output above.
                        exit /b 1
                    )

                    echo.
                    echo ========================================
                    echo Generated delta manifest
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
                    echo ========================================
                    echo Checking delta manifest
                    echo ========================================

                    if not exist "delta\\package\\package.xml" (
                        echo ERROR: Delta manifest not found.
                        exit /b 1
                    )

                    type "delta\\package\\package.xml"

                    echo.
                    echo ========================================
                    echo Checking project configuration
                    echo ========================================

                    if not exist "sfdx-project.json" (
                        echo ERROR: sfdx-project.json not found.
                        exit /b 1
                    )

                    type "sfdx-project.json"

                    echo.
                    echo ========================================
                    echo Validating Salesforce metadata
                    echo ========================================

                    sf project deploy validate ^
                      --manifest "delta\\package\\package.xml" ^
                      --target-org sf-test-jenkins ^
                      --test-level RunLocalTests ^
                      --wait 60

                    set "DEPLOY_EXIT_CODE=%ERRORLEVEL%"

                    echo.
                    echo Salesforce CLI exit code: %DEPLOY_EXIT_CODE%

                    exit /b %DEPLOY_EXIT_CODE%
                '''
            }
        }
    }

    post {
        always {
            echo 'Salesforce CI pipeline completed. Review the console output.'
        }

        success {
            echo 'Pipeline succeeded.'
        }

        failure {
            echo 'Pipeline failed. Review the first actual error in the console output.'
        }
    }
}
