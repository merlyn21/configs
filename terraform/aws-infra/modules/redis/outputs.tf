output "redis_endpoint" {
  value = "${aws_elasticache_replication_group.redis_cluster.primary_endpoint_address}:${aws_elasticache_replication_group.redis_cluster.port}"
}
