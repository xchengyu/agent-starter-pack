# Project name used for resource naming
project_name = "my-rag-agent-from-gcs"

# Your Production Google Cloud project id
prod_project_id = "your-production-project-id"

# Your Staging / Test Google Cloud project id
staging_project_id = "your-staging-project-id"

# Your Google Cloud project ID that will be used to host the Cloud Build pipelines.
cicd_runner_project_id = "your-cicd-project-id"

# Name of the host connection you created in Cloud Build
host_connection_name = "git-my-rag-agent-from-gcs"

# Name of the repository you added to Cloud Build
repository_name = "repo-my-rag-agent-from-gcs"

# The Google Cloud region you will use to deploy the infrastructure
region = "us-central1"
pipeline_cron_schedule = "0 0 * * 0"
vector_search_shard_size = "SHARD_SIZE_SMALL"
vector_search_machine_type = "e2-standard-2"
vector_search_min_replica_count = 1
vector_search_max_replica_count = 1
