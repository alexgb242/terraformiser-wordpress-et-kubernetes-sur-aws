provider "aws"{
    region = "us-east-1"
    profile = "Alex"
}


provider "kubernetes" {
    config_context_cluster = "minikube"
}
