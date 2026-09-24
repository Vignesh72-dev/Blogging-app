# Outputs - public IPs you'll SSH into and use in the rest of the guide

output "jenkins_public_ip"   { value = aws_instance.jenkins.public_ip }
output "sonarqube_public_ip" { value = aws_instance.sonarqube.public_ip }
output "nexus_public_ip"     { value = aws_instance.nexus.public_ip }
output "monitor_public_ip"   { value = aws_instance.monitor.public_ip }
