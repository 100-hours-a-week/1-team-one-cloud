output "instance_id" {
  description = "생성된 EC2 인스턴스의 ID"
  value       = aws_instance.app.id
}

output "instance_public_ip" {
  description = "인스턴스에 할당된 탄력적 IP (EIP)"
  value       = aws_eip.eip.public_ip
}

output "vpc_id" {
  description = "생성된 VPC의 ID"
  value       = aws_vpc.main.id
}

output "ssm_command" {
  description = "SSM Session Manager 접속을 위한 가이드 명령어"
  value       = "aws ssm start-session --target ${aws_instance.app.id}"
}
