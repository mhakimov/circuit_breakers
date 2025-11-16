output "vpc_id" { value = aws_vpc.this.id }
output "vpc" { value = aws_vpc.this }
output "public_subnet_ids" { value = [for s in aws_subnet.public : s.id] }
output "private_subnet_ids" { value = [for s in aws_subnet.private : s.id] }
