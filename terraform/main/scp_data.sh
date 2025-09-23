# Copy labsuser.pem with scp using labsuser.pem and ansible-server public ip
scp -i labsuser.pem inventory.ini ubuntu@107.20.114.118:/home/ubuntu/
scp -i labsuser.pem labsuser.pem ubuntu@107.20.114.118:/home/ubuntu/
scp -i labsuser.pem ../../ansible/ansible-playbook.yml ubuntu@107.20.114.118:/home/ubuntu/
scp -i labsuser.pem ansible_vars.json ubuntu@107.20.114.118:/home/ubuntu/