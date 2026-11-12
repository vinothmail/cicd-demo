pipeline {
    agent any

    environment {
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        IMAGE_NAME = 'vinothmail/cicd-demo'
    }

    stages {

        stage('Test') {
            steps {
                sh 'bash tests/check_html.sh index.html'
            }
        }

        stage('Docker build') {
            steps {
                sh 'docker build -t $IMAGE_NAME:$BUILD_NUMBER .'
            }
        }

        stage('Docker push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                                  usernameVariable: 'DH_USER',
                                                  passwordVariable: 'DH_TOKEN')]) {
                    sh '''
                        echo "$DH_TOKEN" | docker login -u "$DH_USER" --password-stdin
                        docker push $IMAGE_NAME:$BUILD_NUMBER
                        docker logout
                    '''
                }
            }
        }
        stage('Kubernetes cluster') {
            steps {
                sh '''
                    K3S_SERVER=$(terraform -chdir=terraform output -raw k3s_server_private_ip)
                    WORKERS=$(terraform -chdir=terraform output -json k3s_worker_private_ips | jq -r '.[]')
                    SSH_OPTS="ansible_user=ubuntu ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/devops-key"

                    {
                        echo "[k3s_server]"
                        echo "$K3S_SERVER $SSH_OPTS"
                        echo "[k3s_workers]"
                        for w in $WORKERS; do echo "$w $SSH_OPTS"; done
                    } > ansible/k3s_inventory.ini

                    cat ansible/k3s_inventory.ini
                    ansible-playbook -i ansible/k3s_inventory.ini ansible/k3s.yml

                    kubectl --kubeconfig /var/lib/jenkins/.kube/k3s-config get nodes -o wide
                '''
            }
        }
      
        stage('Terraform plan') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform init -input=false
                        terraform validate
                        terraform plan -input=false -out=tfplan
                    '''
                }
            }
        }

        stage('Approval') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    input message: 'Review the Terraform plan in the console log. Deploy?',
                          ok: 'Deploy'
                }
            }
        }

        stage('Terraform apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -input=false tfplan'
                }
            }
        }

        stage('Ansible') {
            steps {
                sh '''
                    WEB_IP=$(terraform -chdir=terraform output -raw web_public_ip)
                    echo "Web server IP: $WEB_IP"
                    echo "Deploying image: $IMAGE_NAME:$BUILD_NUMBER"

                    printf "[web]\\n%s ansible_user=ubuntu ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/devops-key\\n" "$WEB_IP" > ansible/inventory.ini

                    ansible-playbook -i ansible/inventory.ini ansible/playbook.yml \
                        -e "app_image=$IMAGE_NAME:$BUILD_NUMBER"
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
        always {
            sh 'docker image prune -f || true'
        }
        success {
            echo 'Pipeline succeeded.'
        }
        failure {
            echo 'Pipeline failed. Check the stage that turned red.'
        }
        aborted {
            echo 'Deployment was not approved, or the approval timed out. Nothing was changed.'
        }
    }
}
