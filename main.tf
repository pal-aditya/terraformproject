terraform {
  cloud {
    organization = "microsvc"

    workspaces {
      name = "dev"
    }
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.16,<3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_kubernetes_cluster" "ms" {
  resource_group_name = "SillyBeings"
  name                = "sillybeings"
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.ms.kube_admin_config[0].host
  client_key             = base64decode(data.azurerm_kubernetes_cluster.ms.kube_admin_config[0].client_key)
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.ms.kube_admin_config[0].client_certificate)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.ms.kube_admin_config[0].cluster_ca_certificate)
}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = "ms"
  }
}

#resource "kubernetes_resource_quota" "krq" {
#  metadata {
#    name      = "krq"
#    namespace = kubernetes_namespace.ns.metadata[0].name
#  }
#  spec {
#    hard = {
#      "requests.cpu"    = "1"
#      "requests.memory" = "1G"
#      "limits.cpu"      = "2"
#      "limits.memory"   = "1.4G"
#      "pods"            = "20"
#      "services"        = "20"
#    }
#  }
#}

locals {
  name     = ["adservice", "cartservice", "checkoutservice", "currencyservice", "paymentservice", "productcatalogservice", "recommendationservice", "shippingservice"]
  type     = "ClusterIP"
  prt_name = "grpc"
  prt      = [9555, 7070, 5050, 7000, 50051, 3550, 8080, 50051]

  envsforchckoutsvc = [
    { name = "PORT", value = "5050" },
    { name = "PRODUCT_CATALOG_SERVICE_ADDR", value = "productcatalogservice:3550" },
    { name = "SHIPPING_SERVICE_ADDR", value = "shippingservice:50051" },
    { name = "PAYMENT_SERVICE_ADDR", value = "paymentservice:50051" },
    { name = "EMAIL_SERVICE_ADDR", value = "emailservice:5000" },
    { name = "CURRENCY_SERVICE_ADDR", value = "currencyservice:7000" },
    { name = "CART_SERVICE_ADDR", value = "cartservice:7070" }
  ]

  envforfrontend = [
    { name = "PORT", value = "8080" },
    { name = "PRODUCT_CATALOG_SERVICE_ADDR", value = "productcatalogservice:3550" },
    { name = "CURRENCY_SERVICE_ADDR", value = "currencyservice:7000" },
    { name = "CART_SERVICE_ADDR", value = "cartservice:7070" },
    { name = "RECOMMENDATION_SERVICE_ADDR", value = "recommendationservice:8080" },
    { name = "SHIPPING_SERVICE_ADDR", value = "shippingservice:50051" },
    { name = "CHECKOUT_SERVICE_ADDR", value = "checkoutservice:5050" },
    { name = "AD_SERVICE_ADDR", value = "adservice:9555" },
    { name = "SHOPPING_ASSISTANT_SERVICE_ADDR", value = "shoppingassistantservice:80" }
  ]

  services = {
    for idx, svc in local.name : svc => {
      port = local.prt[idx]
    }
  }
}

resource "kubernetes_deployment" "shippingservice" {
  metadata {
    name      = "shippingservice"
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      "app" = "shippingservice"
    }
  }
  spec {
    selector {
      match_labels = {
        "app" = "shippingservice"
      }
    }
    template {
      metadata {
        labels = {
          "app" = "shippingservice"
        }
      }
      spec {
        security_context {
          run_as_user                      = 1000
          fs_group                         = 1000
          run_as_group                     = 1000
          run_as_non_root                  = true
#          termination_grace_period_seconds = 5
        }
        container {
          name = "shippingservice"
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            read_only_root_filesystem = true
            privileged                = false
          }
          image = "aditya090/projectk8s:msshippingsvc"
          port {
            container_port = 50051
          }
          env {
            name  = "PORT"
            value = "50051"
          }
          env {
            name  = "DISABLE_PROFILER"
            value = "1"
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "recommendationservice" {
  metadata {
    name      = "recommendationservice"
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      "app" = "recommendationservice"
    }
  }
  spec {
    selector {
      match_labels = {
        "app" = "recommendationservice"
      }
    }
    template {
      metadata {
        labels = {
          "app" = "recommendationservice"
        }
      }
      spec {
        security_context {
          run_as_user                      = 1000
          fs_group                         = 1000
          run_as_group                     = 1000
          run_as_non_root                  = true
#          termination_grace_period_seconds = 5
        }
        container {
          name = "recommendationservice"
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            read_only_root_filesystem = true
            privileged                = false
          }
          image = "aditya090/projectk8s:msrecommendationsvc"
          port {
            container_port = 8080
          }
          env {
            name  = "PORT"
            value = "8080"
          }
          env {
            name  = "PRODUCT_CATALOG_SERVICE_ADDR"
            value = "productcatalogservice:3550"
          }
          env {
            name  = "DISABLE_PROFILER"
            value = "1"
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "productcatalogservice" {
  metadata {
    name      = "productcatalogservice"
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      "app" = "productcatalogservice"
    }
  }
  spec {
    selector {
      match_labels = {
        "app" = "productcatalogservice"
      }
    }
    template {
      metadata {
        labels = {
          "app" = "productcatalogservice"
        }
      }
      spec {
        security_context {
          run_as_user                      = 1000
          fs_group                         = 1000
          run_as_group                     = 1000
          run_as_non_root                  = true
 #         termination_grace_period_seconds = 5
        }
        container {
          name = "productcatalogservice"
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            read_only_root_filesystem = true
            privileged                = false
          }
          image = "aditya090/projectk8s:msprodctcatalogue"
          port {
            container_port = 3550
          }
          env {
            name  = "PORT"
            value = "3550"
          }
          env {
            name  = "DISABLE_PROFILER"
            value = "1"
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "paymentsvc" {
  metadata {
    name      = "paymentservice"
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      "app" = "paymentservice"
    }
  }
  spec {
    selector {
      match_labels = {
        "app" = "paymentservice"
      }
    }
    template {
      metadata {
        labels = {
          "app" = "paymentservice"
        }
      }
      spec {
        security_context {
          run_as_user                      = 1000
          fs_group                         = 1000
          run_as_group                     = 1000
          run_as_non_root                  = true
  #        termination_grace_period_seconds = 5
        }
        container {
          name = "paymentservice"
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            read_only_root_filesystem = true
            privileged                = false
          }
          image = "aditya090/projectk8s:mspaymntsvc"
          port {
            container_port = 50051
          }
          env {
            name  = "PORT"
            value = "50051"
          }
          env {
            name  = "DISABLE_PROFILER"
            value = "1"
          }
        }
      }
    }
  }
}

#@variable "secretpass"{}
#variable "smtp_pass" {
#  description = "SMTP password for Gmail or email service"
#  type        = string
#  sensitive   = true
#}

resource "kubernetes_secret" "scret" {
  metadata {
    name      = "secretsvc"
    namespace = kubernetes_namespace.ns.metadata[0].name
  }
  data = {
    SMTP_PASS = "XXXXXXXXXXXXXXX" #paste your values
  }
  type = "Opaque"
}
resource "kubernetes_config_map" "emailcnfg" {
  metadata {
    name      = "smtp"
    namespace = kubernetes_namespace.ns.metadata[0].name
  }
  data = {
    SMTP_SERVER = "smtp.gmail.com"
    SMTP_PORT   = "587"
    SMTP_USER   = "k609627@gmail.com"
  }
}

resource "kubernetes_deployment" "frntend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      "app" = "frontend"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "frontend"
      }
    }
    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }
      spec {
        security_context {
          run_as_non_root                  = true
          run_as_user                      = 1000
          fs_group                         = 1000
          run_as_group                     = 1000
#          termination_grace_period_seconds = 5
        }
        container {
          name = "server"
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            read_only_root_filesystem = true
            privileged                = false
          }
          image = "aditya090/projectk8s:msfrontendsvc-v1"
          port {
            container_port = 8080
          }
          dynamic "env" {
            for_each = local.envforfrontend
            content {
              name  = env.value.name
              value = env.value.value
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "emailsvc" {
  metadata {
    name      = "emailservice"
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      "app" = "emailservice"
    }
  }
  spec {
    selector {
      match_labels = {
        "app" = "emailservice"
      }
    }
    template {
      metadata {
        name = "emailservice"
        labels = {
          "app" = "emailservice"
        }
      }
      spec {
        security_context {
#          termination_grace_period_seconds = 5
          run_as_user                      = 1000
          run_as_non_root                  = true
          run_as_group                     = 1000
          fs_group                         = 1000
        }
        container {
          name = "emailservice"
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            privileged                = false
            read_only_root_filesystem = true
          }
          image = "aditya090/projectk8s:msemailsvc-v1.2"
          port {
            container_port = 8080
          }
          env {
            name  = "PORT"
            value = "8080"
          }
          env {
            name  = "DUMMY_MODE"
            value = "0"
          }
          env {
            name  = "ENABLE_REAL_EMAIL"
            value = "true"
          }
          env {
            name  = "DISABLE_PROFILER"
            value = "1"
          }
          env {
            name = "SMTP_SERVER"
            value_from {
              config_map_key_ref {
                name = "smtp"
                key  = "SMTP_SERVER"
              }
            }
          }
          env {
            name = "SMTP_PORT"
            value_from {
              config_map_key_ref {
                name = "smtp"
                key  = "SMTP_PORT"
              }
            }
          }
          env {
            name = "SMTP_USER"
            value_from {
              config_map_key_ref {
                name = "smtp"
                key  = "SMTP_USER"
              }
            }
          }
          env {
            name = "SMTP_PASS"
            value_from {
              secret_key_ref {
                name = "secretsvc"
                key  = "SMTP_PASS"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "currencysvc" {
  metadata {
    name      = "currencyservice"
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      app = local.name[3]
    }
  }
  spec {
    selector {
      match_labels = {
        app = local.name[3]
      }
    }
    template {
      metadata {
        labels = {
          app = local.name[3]
        }
      }
      spec {
        security_context {
          run_as_user                      = 1000
          fs_group                         = 1000
          run_as_group                     = 1000
          run_as_non_root                  = true
#          termination_grace_period_seconds = 5
        }
        container {
          name = local.name[3]
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            read_only_root_filesystem = true
            privileged                = false
          }
          image = "aditya090/projectk8s:mscurrencysvc-v1"
          port {
            container_port = 7000
          }
          env {
            name  = "PORT"
            value = "7000"
          }
          env {
            name  = "DISABLE_PROFILER"
            value = "1"
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "checkoutsvc" {
  metadata {
    name      = local.name[2]
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      app = local.name[2]
    }
  }
  spec {
    selector {
      match_labels = {
        app = local.name[2]
      }
    }
    template {
      metadata {
        labels = {
          app = local.name[2]
        }
      }
      spec {
        security_context {
#          termination_grace_period_seconds = 5
          run_as_user                      = 1000
          run_as_non_root                  = true
          run_as_group                     = 1000
          fs_group                         = 1000
        }
        container {
          name = local.name[2]
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            privileged                = false
            read_only_root_filesystem = true
          }
          image = "aditya090/projectk8s:mscheckoutsvc"
          port {
            container_port = 5050
          }
          dynamic "env" {
            for_each = local.envsforchckoutsvc
            content {
              name  = env.value.name
              value = env.value.value
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "rediscartsvc" {
  metadata {
    name      = "redis-cart"
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      app = "redis-cart"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "redis-cart"
      }
    }
    template {
      metadata {
        name = "redis-cart"
        labels = {
          app = "redis-cart"
        }
      }
      spec {
        security_context {
#          termination_grace_period_seconds = 5
          run_as_user                      = 1000
          run_as_non_root                  = true
          run_as_group                     = 1000
          fs_group                         = 1000
        }
        container {
          name = "redis"
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            privileged                = false
            read_only_root_filesystem = true
          }
          image = "redis:alpine"
          port {
            container_port = 6379
          }
          env {
            name  = "REDIS_ADDR"
            value = "redis-cart:6379"
          }
          volume_mount {
            name       = "redis-data"
            mount_path = "/data"
          }
        }
        volume {
          name = "redis-data"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_deployment" "cartsvc" {
  metadata {
    name      = local.name[1]
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      app = local.name[1]
    }
  }
  spec {
    selector {
      match_labels = {
        app = local.name[1]
      }
    }
    template {
      metadata {
        name = local.name[1]
        labels = {
          app = local.name[1]
        }
      }
      spec {
        security_context {
#          termination_grace_period_seconds = 5
          run_as_user                      = 1000
          run_as_non_root                  = true
          run_as_group                     = 1000
          fs_group                         = 1000
        }
        container {
          name = local.name[1]
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            privileged                = false
            read_only_root_filesystem = true
          }
          image = "aditya090/projectk8s:mscartsvc"
          port {
            container_port = local.prt[1]
          }
          env {
            name  = "REDIS_ADDR"
            value = "redis-cart:6379"
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "ads" {
  metadata {
    name      = "adservice"
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      "app" = "adservice"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "adservice"
      }
    }
    template {
      metadata {
        labels = {
          app = "adservice"
        }
      }
      spec {
        security_context {
          run_as_user     = 1000
          fs_group        = 1000
          run_as_non_root = true
          run_as_group    = 1000
        }
        container {
          name = "adsvc"
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            privileged                = false
            read_only_root_filesystem = true
          }
          image = "aditya090/projectk8s:msads-fix"
          port {
            container_port = 9555
          }
          env {
            name  = "PORT"
            value = "9555"
          }
        }
      }
    }
  }
}

# Dynamic services for multiple microservices
resource "kubernetes_service" "dynamic" {
  for_each = local.services

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      app = each.key
    }
  }

  spec {
    selector = {
      app = each.key
    }
    type = local.type
    port {
      name        = local.prt_name
      port        = each.value.port
      target_port = each.value.port
    }
  }
}

resource "kubernetes_service" "rediscart" {
  metadata {
    name      = "redis-cart"
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      app = "redis-cart"
    }
  }
  spec {
    selector = {
      app = "redis-cart"
    }
    type = local.type
    port {
      name        = "tcp-redis"
      port        = 6379
      target_port = 6379
    }
  }
}

resource "kubernetes_service" "emailservice" {
  metadata {
    name      = "emailservice"
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      app = "emailservice"
    }
  }
  spec {
    selector = {
      app = "emailservice"
    }
    type = local.type
    port {
      name        = local.prt_name
      port        = 5000
      target_port = 8080
    }
  }
}

resource "kubernetes_service" "frntend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      app = "frontend"
    }
  }
  spec {
    selector = {
      app = "frontend"
    }
    type = local.type
    port {
      name        = "http"
      port        = 80
      target_port = 8080
    }
  }
}

resource "kubernetes_service" "frontendexternal" {
  metadata {
    name      = "frontend-external"
    namespace = kubernetes_namespace.ns.metadata[0].name
    labels = {
      app = "frontend"
    }
  }
  spec {
    selector = {
      app = "frontend"
    }
    type = "LoadBalancer"
    port {
      name        = "http"
      port        = 80
      target_port = 8080
    }
  }
}
