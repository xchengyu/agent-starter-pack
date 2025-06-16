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

provider "google" {
  region = var.region
  user_project_override = true
}

resource "google_storage_bucket" "bucket_load_test_results" {
  name                        = "${var.cicd_runner_project_id}-${var.project_name}-load-test"
  location                    = var.region
  project                     = var.cicd_runner_project_id
  uniform_bucket_level_access = true
  force_destroy               = true
  depends_on                  = [resource.google_project_service.cicd_services, resource.google_project_service.shared_services]
}

resource "google_storage_bucket" "logs_data_bucket" {
  for_each                    = toset(local.all_project_ids)
  name                        = "${each.value}-${var.project_name}-logs-data"
  location                    = var.region
  project                     = each.value
  uniform_bucket_level_access = true
  force_destroy               = true

  depends_on = [resource.google_project_service.cicd_services, resource.google_project_service.shared_services]
}



resource "google_storage_bucket" "data_ingestion_pipeline_gcs_root" {
  for_each                    = local.deploy_project_ids
  name                        = "${each.value}-${var.project_name}-rag"
  location                    = var.region
  project                     = each.value
  uniform_bucket_level_access = true
  force_destroy               = true

  depends_on = [resource.google_project_service.cicd_services, resource.google_project_service.shared_services]
}



resource "google_storage_bucket" "vector_search_data_bucket" {
  for_each                    = local.deploy_project_ids
  name                        = "${each.value}-${var.project_name}-vs"
  location                    = var.region
  project                     = each.value
  uniform_bucket_level_access = true
  force_destroy               = true

  depends_on = [resource.google_project_service.cicd_services, resource.google_project_service.shared_services]
}

resource "google_vertex_ai_index" "vector_search_index_staging" {
  project = var.staging_project_id
  region = var.region
  display_name = "${var.project_name}-vector-search"
  description = "vector search index for test"
  metadata {
    config {
      dimensions = var.vector_search_embedding_size
      shard_size = var.vector_search_shard_size
      distance_measure_type = "DOT_PRODUCT_DISTANCE"
      approximate_neighbors_count = var.vector_search_approximate_neighbors_count
      algorithm_config {
        tree_ah_config {
        }
      }
    }
  }
  index_update_method = "STREAM_UPDATE"
}

resource "google_vertex_ai_index_endpoint" "vector_search_index_endpoint_staging" {
  project      = var.staging_project_id
  region       = var.region
  display_name = "${var.project_name}-vector-search-endpoint"
  public_endpoint_enabled = true
  depends_on = [google_vertex_ai_index.vector_search_index_staging]
}

resource "google_vertex_ai_index_endpoint_deployed_index" "vector_search_index_deployment_staging" {
    index_endpoint = google_vertex_ai_index_endpoint.vector_search_index_endpoint_staging.id
    index = google_vertex_ai_index.vector_search_index_staging.id
    deployed_index_id = replace("${var.project_name}_deployed_index", "-", "_")
    depends_on = [
      google_vertex_ai_index.vector_search_index_staging,
      google_vertex_ai_index_endpoint.vector_search_index_endpoint_staging
    ]
}

resource "google_vertex_ai_index" "vector_search_index_prod" {
  project = var.prod_project_id
  region = var.region
  display_name = "${var.project_name}-vector-search"
  description = "vector search index for test"
  metadata {
    config {
      dimensions = var.vector_search_embedding_size
      distance_measure_type = "DOT_PRODUCT_DISTANCE"
      approximate_neighbors_count = var.vector_search_approximate_neighbors_count
      shard_size = var.vector_search_shard_size
      algorithm_config {
        tree_ah_config {
        }
      }
    }
  }
  index_update_method = "STREAM_UPDATE"
}

resource "google_vertex_ai_index_endpoint" "vector_search_index_endpoint_prod" {
  project      = var.prod_project_id
  region       = var.region
  display_name = "${var.project_name}-vector-search-endpoint"
  public_endpoint_enabled = true
  depends_on = [google_vertex_ai_index.vector_search_index_prod]
}

resource "google_vertex_ai_index_endpoint_deployed_index" "vector_search_index_deployment_prod" {
    index_endpoint = google_vertex_ai_index_endpoint.vector_search_index_endpoint_prod.id
    index = google_vertex_ai_index.vector_search_index_prod.id
    deployed_index_id = replace("${var.project_name}_deployed_index", "-", "_")
    dedicated_resources {
      machine_spec {
        machine_type = var.vector_search_machine_type
      }
      min_replica_count = var.vector_search_min_replica_count
      max_replica_count = var.vector_search_max_replica_count
    }
    depends_on = [
      google_vertex_ai_index.vector_search_index_prod,
      google_vertex_ai_index_endpoint.vector_search_index_endpoint_prod
    ]
}



