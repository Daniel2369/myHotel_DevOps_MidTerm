# Copy labsuser.pem with scp using labsuser.pem and ansible-server public ip
scp -i labsuser.pem inventory.ini ubuntu@52.90.147.247:/home/ubuntu/
scp -i labsuser.pem labsuser.pem ubuntu@52.90.147.247:/home/ubuntu/
scp -i labsuser.pem ../../ansible/ansible-playbook.yml ubuntu@52.90.147.247:/home/ubuntu/
scp -i labsuser.pem ansible_vars.json ubuntu@52.90.147.247:/home/ubuntu/