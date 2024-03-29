# Harden Staging Pipeline with Quality Gate

In this lab you'll add an additional quality gate to your CI pipeline. In other words, an end-to-end check will verify the functionality of the sockshop application in the staging environment.

## Step 1: Add e2e Test to Staging Pipeline
1. Uncomment the following snippet in the Jenkins pipeline of `k8s-deploy-staging`.
    ```
    stage('Run production ready e2e check in staging') {
      steps {
        echo "Waiting for the service to start..."
        sleep 150
        recordDynatraceSession (
          envId: 'Dynatrace Tenant',
          testCase: 'loadtest',
          tagMatchRules: tagMatchRules
        ) 
        {
          container('jmeter') {
            script {
              def status = executeJMeter ( 
                scriptName: "jmeter/front-end_e2e_load.jmx",
                resultsDir: "e2eCheck_${env.APP_NAME}",
                serverUrl: "front-end.staging", 
                serverPort: 8080,
                checkPath: '/health',
                vuCount: 10,
                loopCount: 5,
                LTN: "e2eCheck_${BUILD_NUMBER}",
                funcValidation: false,
                avgRtValidation: 4000
              )
              if (status != 0) {
                currentBuild.result = 'FAILED'
                error "Production ready e2e check in staging failed."
              }
            }
          }
        }
        perfSigDynatraceReports(
          envId: 'Dynatrace Tenant', 
          nonFunctionalFailure: 1, 
          specFile: "monspec/e2e_perfsig.json"
        )
      }
    }
    ```

## Step 2: Set the Upper and Lower Limit in the Performance Signature
1. Open the file `monspec\e2e_perfsig.json`.
1. Set the upper and lower limit for the response time as follows:
    ```
    "upperSevere" : 800,
    "upperWarning" : 600
    ```
1. Commit/Push the changes to your GitHub repository *k8s-deploy-staging*.

## Step 3: Add a quality gate for Service Method addToCart
In some cases it is not sufficient to look at the Service level for performance degradations. This is certainly so in large tests that hit many endpoints of a service. This could lead to the results being skewed as very fast responses on one service method could average out the (perhaps fewer in number) slow requests on the degraded service methods.

To remediate this, we will add another quality gate to our Performance Signature.

1. Open the file `monspec\e2e_perfsig.json`.
1. Add another quality gate like below
    ```
    {
        "timeseriesId" : "com.dynatrace.builtin:servicemethod.responsetime",
        "aggregation" : "avg",
        "entityIds": "[ADDTOCART_SERVICE-METHOD]",
        "upperSevere": 800.0,
        "upperWarning" : 600.0
    },
    ```
1. Replace [ADDTOCART_SERVICE-METHOD] with the Entity Id of the Add To Cart Service Method. The easiest way to retrieve it is by navigating to the `ItemsController` service in `staging` inside Dynatrace.
  ![](../assets/itemscontroller-staging.png)
1. Click on `View requests`
1. Scroll down to the bottom of the page to `Top Contributors` and click on `addToCart` 
  ![](../assets/itemscontroller-contributors.png)
1. Make `addToCart` a `Key Request`
  ![](../assets/itemscontroller-addtocart-keyrequest.png)
1. In the address bar of your browser window you can find the Entity Id of the `addToCart` Service Method
  ![](../assets/itemscontroller-addtocart-servicemethod.png)
1. Copy this value into the performance signature
1. Commit/Push the changes to your GitHub repository *k8s-deploy-staging*.

---

:arrow_forward: [Next Step: Simulate Early Pipeline Break](../02_Simulate_Early_Pipeline_Break)
