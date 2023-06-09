package terraform_test

import (
	_ "fmt"
	"github.com/aws/aws-sdk-go/service/cloudwatchlogs"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"io"
	"net/http"
	"os"
	"regexp"
	"testing"
	"time"
	AWS "github.com/aws/aws-sdk-go/aws"
	aws "github.com/gruntwork-io/terratest/modules/aws"
)


const PlanFilePath = "plan.out"

const FnName = "test-fn-name"
const Concurrency = 2
const TTL = 12
const Memory = 188
const LogLevel = "trace"
const Endpoint = "http://localhost:4566"
const Region = "eu-west-1"
const LogMessage = "test message from terratest log event!"

func configureTerraformWithPlan(t *testing.T, target string) *terraform.Options {
	return terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform",
		VarFiles:     []string{"terraform.tfvars"},
		NoColor:      true,
		Targets: 		[]string{target},
		PlanFilePath: PlanFilePath,
	})
}

func configureTerraform(t *testing.T, target string) *terraform.Options {
	return terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform",
		VarFiles:     []string{"terraform.tfvars"},
		NoColor:      true,
		Targets: 		[]string{target},
	})
}

func TestModule(t *testing.T) {
    for _, testFuncs := range []struct{
        name string
        tfunc func(*testing.T)
    }{
			{"Plan Test", planTest},
			{"Unit Test", unitTest},
			{"Integration Test", integrationTest},
		} {
        t.Run(testFuncs.name, testFuncs.tfunc)
    }
}

func integrationTest(t *testing.T) {
	terraformOpts := configureTerraform(t, "module.test")
	defer terraform.Destroy(t, terraformOpts)
	var streamParams = cloudwatchlogs.CreateLogStreamInput{
		LogGroupName: AWS.String("test2"),
		LogStreamName: AWS.String("test2"),
	}
	var params = cloudwatchlogs.PutLogEventsInput{
		LogEvents: []*cloudwatchlogs.InputLogEvent{
			{
				Message:   AWS.String(LogMessage),
				Timestamp: AWS.Int64(time.Now().Unix() * 1000),
			},
		},
		LogGroupName: AWS.String("test2"),
		LogStreamName: AWS.String("test2"),
	}

	// Init and Apply TF
	terraform.InitAndApply(t, terraformOpts)

	// Create log stream
	client := aws.NewCloudWatchLogsClient(t, Region)
	client.Endpoint = "http://127.0.0.1:4566"
	client.CreateLogStream(&streamParams)


	// Create ELK index & alias (if not exists)
	elkCreateIndex(t)
	elkCreateAlias(t)

	// Simulate aws log event
	req, _ := client.PutLogEventsRequest(&params)
	err := req.Send()

	assert.NoError(t, err)

	// Wait for lambda to post logs to ELK and ELK to index them
	time.Sleep(10 * time.Second)

	// Get logs from ELK
	getLogsResp, getLogsBody := elkGetLogs(t)

	assert.Equal(t, 200, getLogsResp.StatusCode)
	assert.Regexp(
		t,
		regexp.MustCompile(LogMessage),
		getLogsBody,
	)

	// Delete ELK index & alias
	elkDeleteAlias(t)
	elkDeleteIndex(t)

	terraform.Destroy(t, terraformOpts)
}

func unitTest(t *testing.T) {
	terraformOpts := configureTerraform(t, "module.test")
	defer terraform.Destroy(t, terraformOpts)

	// Init & Apply
	terraform.Apply(t, terraformOpts)

	t.Run("CloudWatch Dashboard Test", cloudWatchDashboardTest)
	t.Run("Subscription Filters Test", subscriptionFiltersTest)
	t.Run("Subscription Permission Test", subscriptionPermissionTest)

	terraform.Destroy(t, terraformOpts)
}

func cloudWatchDashboardTest(t *testing.T) {
	t.Parallel()
	terraformOpts := configureTerraform(t, "module.test")

	// Dashboard should exist and have the correct name
	assert.Regexp(
		t,
		regexp.MustCompile("arn:aws:cloudwatch::\\d{12}dashboard/" + FnName + "-overview"),
		terraform.Output(t, terraformOpts, "cloudwatch_dashboard"),
	)
}

func subscriptionFiltersTest(t *testing.T) {
	t.Parallel()
	terraformOpts := configureTerraform(t, "module.test")

	subscriptions := terraform.OutputListOfObjects(t, terraformOpts, "cloudwatch_subscriptions")
	subscriptionsLogGroupNames := []string{
		"test",
		"test2",
	}
	subscriptionsLen := len(subscriptions)
	subscDestRegExp := "arn:aws:lambda:" + Region + ":\\d{12}:function:" + FnName

	// Should have exact number of subscriptions as log groups
	assert.Equal(t, 2, subscriptionsLen)

	// For each subscription, check if it has the correct values (destination, log, distribution etc.)
	for i := 1; i < subscriptionsLen; i++ {
		expectedLogGroupName := subscriptionsLogGroupNames[i]
		expectedName := expectedLogGroupName + "-log-forwarder-subscription"

		assert.Regexp(
			t,
			regexp.MustCompile(subscDestRegExp),
			subscriptions[i]["destination_arn"],
		)

		assert.Equal(t, "ByLogStream", subscriptions[i]["distribution"])
		assert.Equal(t, expectedLogGroupName, subscriptions[i]["log_group_name"])
		assert.Equal(t, expectedName, subscriptions[i]["name"])
	}
}

func subscriptionPermissionTest(t *testing.T) {
	t.Parallel()
	terraformOpts := configureTerraform(t, "module.test")

	permissions := terraform.OutputListOfObjects(t, terraformOpts, "log_subscription_permission")
	subscriptionsLogGroupNames := []string{
		"test",
		"test2",
	}
	permissionsLen := len(permissions)

	// Should have exact number of permissions as subscriptions
	assert.Equal(t, 2, permissionsLen)

	// For each permission, check if it has the correct values (source_arn, statement_id, etc.)
	for i := 1; i < permissionsLen; i++ {
		subscDestRegExp := "arn:aws:logs:" + Region + ":\\d{12}:log-group:" + subscriptionsLogGroupNames[i] + ":*"
		exepectedStatementID := subscriptionsLogGroupNames[i] + "-AllowExecutionFromCloudWatch"

		assert.Equal(t, "lambda:InvokeFunction", permissions[i]["action"])
		assert.Equal(t, subscriptionsLogGroupNames[i] + "-AllowExecutionFromCloudWatch", permissions[i]["id"])
		assert.Equal(t, "logs."+ Region +".amazonaws.com", permissions[i]["principal"])
		assert.Equal(t, FnName, permissions[i]["function_name"])
		assert.Equal(t, exepectedStatementID, permissions[i]["statement_id"])

		assert.Regexp(
			t,
			regexp.MustCompile(subscDestRegExp),
			permissions[i]["source_arn"],
		)
	}
}

func planTest(t *testing.T) {
	terraformOpts := configureTerraformWithPlan(t, "module.test")

	defer terraform.Destroy(t, terraformOpts)

	// Init & Plan & Show
	plan := terraform.InitAndPlanAndShowWithStruct(t, terraformOpts)

	// Apply and verify if no error occured
	_, applyErr := terraform.ApplyE(t, terraformOpts)
	assert.NoError(t, applyErr)

	expectedPlanKey := []string{
		"module.test.aws_cloudwatch_dashboard.log_forwarder[0]",
		"module.test.aws_lambda_permission.allow_cloudwatch_to_invoke[0]",
		"module.test.aws_lambda_permission.allow_cloudwatch_to_invoke[1]",
		"module.test.aws_cloudwatch_log_subscription_filter.log_forwarder[0]",
		"module.test.aws_cloudwatch_log_subscription_filter.log_forwarder[1]",
		"module.test.aws_iam_role.lambda_task_execution_role",
		"module.test.aws_iam_role_policy_attachment.lambda_task_execution_role",
		"module.test.aws_lambda_function.log_forwarder",
	}

	// For each expected key, check if it exists in the plan
	for _, key := range expectedPlanKey {
		terraform.AssertPlannedValuesMapKeyExists(t, plan, key)
	}

	// Destroy and verify if no error occured
	_, destroyErr := terraform.DestroyE(t, terraformOpts)
	assert.NoError(t, destroyErr)

	// Remove plan file for next test
	os.Remove("../terraform/" + PlanFilePath)
}

func elkCreateIndex(t *testing.T) *http.Response {
	req, err := http.NewRequest("PUT", "http://localhost:9200/test?pretty", nil)
	if err != nil {
		t.Fatal(err)
	}
	resp, err := http.DefaultClient.Do(req)
	defer resp.Body.Close()
	if err != nil {
		t.Fatal(err)
	}
	return resp
}

func elkDeleteIndex(t *testing.T) *http.Response {
	req, err := http.NewRequest("RELETE", "http://localhost:9200/test?pretty", nil)
	if err != nil {
		t.Fatal(err)
	}
	resp, err := http.DefaultClient.Do(req)
	defer resp.Body.Close()
	if err != nil {
		t.Fatal(err)
	}
	return resp
}

func elkCreateAlias(t *testing.T) *http.Response {
	req, err := http.NewRequest("PUT", "http://localhost:9200/test/_alias/test_1?pretty", nil)
	if err != nil {
		t.Fatal(err)
	}
	resp, err := http.DefaultClient.Do(req)
	defer resp.Body.Close()
	if err != nil {
		t.Fatal(err)
	}
	return resp
}

func elkDeleteAlias(t *testing.T) *http.Response {
	req, err := http.NewRequest("DELETE", "http://localhost:9200/test/_alias/test_1?pretty", nil)
	if err != nil {
		t.Fatal(err)
	}
	resp, err := http.DefaultClient.Do(req)
	defer resp.Body.Close()
	if err != nil {
		t.Fatal(err)
	}
	return resp
}

func elkGetLogs(t *testing.T) (*http.Response, string) {
	req, err := http.NewRequest("GET", "http://localhost:9200/test/_search?pretty=true&q=*:*", nil)
	if err != nil {
		t.Fatal(err)
	}

	resp, err := http.DefaultClient.Do(req)
	defer resp.Body.Close()
	if err != nil {
		t.Fatal(err)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatal(err)
	}
	return resp, string(body)
}
