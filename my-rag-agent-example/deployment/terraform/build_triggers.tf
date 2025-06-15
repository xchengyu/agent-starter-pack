# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# a. Create PR checks trigger
resource "google_cloudbuild_trigger" "pr_checks" {
  name            = "pr-${var.project_name}"
  project         = var.cicd_runner_project_id
  location        = var.region
  description     = "Trigger for PR checks"
  service_account = resource.google_service_account.cicd_runner_sa.id

  repository_event_config {
    repository = "projects/${var.cicd_runner_project_id}/locations/${var.region}/connections/${var.host_connection_name}/repositories/${var.repository_name}"
    pull_request {
      branch = "main"
    }
  }

  filename = "deployment/ci/pr_checks.yaml"
  included_files = [
    "app/**",
    "data_ingestion/**",
    "tests/**",
    "deployment/**",
    "uv.lock",
  
    "data_ingestion/**",
  
  ]
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
  depends_on = [resource.google_project_service.cicd_services, resource.google_project_service.shared_services]
}

# b. Create CD pipeline trigger
resource "google_cloudbuild_trigger" "cd_pipeline" {
  name            = "cd-${var.project_name}"
  project         = var.cicd_runner_project_id
  location        = var.region
  service_account = resource.google_service_account.cicd_runner_sa.id
  description     = "Trigger for CD pipeline"

  repository_event_config {
    repository = "projects/${var.cicd_runner_project_id}/locations/${var.region}/connections/${var.host_connection_name}/repositories/${var.repository_name}"
    push {
      branch = "main"
    }
  }

  filename = "deployment/cd/staging.yaml"
  included_files = [
    "app/**",
    "data_ingestion/**",
    "tests/**",
    "deployment/**",
    "uv.lock"
  ]
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
  substitutions = {
    _STAGING_PROJECT_ID            = var.staging_project_id
    _BUCKET_NAME_LOAD_TEST_RESULTS = resource.google_storage_bucket.bucket_load_test_results.name
    _REGION                        = var.region


    _PIPELINE_GCS_ROOT             = "gs://${resource.google_storage_bucket.data_ingestion_pipeline_gcs_root["staging"].name}"
    _PIPELINE_SA_EMAIL             = resource.google_service_account.vertexai_pipeline_app_sa["staging"].email
    _PIPELINE_CRON_SCHEDULE        = var.pipeline_cron_schedule

    _DATA_STORE_ID                 = resource.google_discovery_engine_data_store.data_store_staging.data_store_id
    _DATA_STORE_REGION             = var.data_store_region


    # Your other CD Pipeline substitutions
  }
  depends_on = [resource.google_project_service.cicd_services, resource.google_project_service.shared_services]

}

# c. Create Deploy to production trigger
resource "google_cloudbuild_trigger" "deploy_to_prod_pipeline" {
  name            = "deploy-${var.project_name}"
  project         = var.cicd_runner_project_id
  location        = var.region
  description     = "Trigger for deployment to production"
  service_account = resource.google_service_account.cicd_runner_sa.id
  repository_event_config {
    repository = "projects/${var.cicd_runner_project_id}/locations/${var.region}/connections/${var.host_connection_name}/repositories/${var.repository_name}"
  }
  filename = "deployment/cd/deploy-to-prod.yaml"
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
  approval_config {
    approval_required = true
  }
  substitutions = {
    _PROD_PROJECT_ID             = var.prod_project_id
    _REGION                      = var.region


    _PIPELINE_GCS_ROOT             = "gs://${resource.google_storage_bucket.data_ingestion_pipeline_gcs_root["prod"].name}"
    _PIPELINE_SA_EMAIL             = resource.google_service_account.vertexai_pipeline_app_sa["prod"].email
    _PIPELINE_CRON_SCHEDULE        = var.pipeline_cron_schedule

    _DATA_STORE_ID                 = resource.google_discovery_engine_data_store.data_store_prod.data_store_id
    _DATA_STORE_REGION             = var.data_store_region


    # Your other Deploy to Prod Pipeline substitutions
  }
  depends_on = [resource.google_project_service.cicd_services, resource.google_project_service.shared_services]

}
