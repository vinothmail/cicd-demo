Developer ──push──▶ Git (GitHub)
                      │ webhook
                      ▼
                   Jenkins  (the "orchestrator")
                      │
         ┌────────────┼─────────────┐
         ▼            ▼             ▼
      1. Build     2. Terraform   3. Ansible
      (check       creates EC2    installs nginx +
      index.html)                 copies index.html
                                        │
                                        ▼
Who does what
Tool	Role
Git/GitHub	Stores code (index.html, Terraform files, Ansible playbook, Jenkinsfile)
Jenkins	The “robot” that runs the steps in order when code is pushed
Terraform	Creates the web server EC2
Ansible	Installs nginx on it and deploys index.html
Prometheus (later)	Monitors the web server

Each stage works on its own, so you always have something running.

Stage 1: Launch the Jenkins EC2 and install Jenkins, Git, Terraform and Ansible.
Stage 2: Create the GitHub repo with index.html. Create a Jenkins job that pulls it (manual “Build Now”).
Stage 3: Add Terraform to the job so it creates the web EC2.
Stage 4: Add Ansible so it installs nginx and deploys index.html.
Stage 5: Turn it into a Jenkinsfile (pipeline as code) with stages: Checkout → Terraform → Ansible.
Stage 6: Add a GitHub webhook so a git push triggers it automatically.
Stage 7: Add Prometheus and Node Exporter for monitoring.
