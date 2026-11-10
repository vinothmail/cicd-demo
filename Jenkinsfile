pipeline {
    agent any

    environment {
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }

    stages {

        stage('Build check') {
            steps {
                sh '''
                    echo "Build started"
                    ls -l
                    test -f index.html
                    grep -qi "<html" index.html
                    echo "index.html looks good"
                '''
            }
        }

        stage('Terraform') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform init -input=false -migrate-state -force-copy
                        terraform validate
                        terraform plan -input=false
                        terraform apply -input=false -auto-approve
                    '''
                }
            }
        }

        stage('Ansible') {
            steps {
                sh '''
                    WEB_IP=$(terraform -chdir=terraform output -raw web_public_ip)
                    echo "Web server IP: $WEB_IP"

                    printf "[web]\\n%s ansible_user=ubuntu ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/devops-key\\n" "$WEB_IP" > ansible/inventory.ini

                    ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
                '''
            }
        }

        stage('Register monitoring') {
            steps {
                sh '''
                    WEB_PRIVATE_IP=$(terraform -chdir=terraform output -raw web_private_ip)
                    echo "Registering $WEB_PRIVATE_IP:9100 with Prometheus"
                    printf '[{"targets": ["%s:9100"], "labels": {"server": "web-server"}}]\\n' "$WEB_PRIVATE_IP" > /etc/prometheus/targets/web.json
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline succeeded. Open the web server IP in your browser.'
        }
        failure {
            echo 'Pipeline failed. Check the stage that turned red.'
        }
    }
}
