#!/usr/bin/python3

import argparse
import os
import subprocess

def auto_rename(file, dir):
    base, ext = os.path.splitext(file)
    if os.path.exists(os.path.join(dir, file)):
        i = 1
        while os.path.exists(os.path.join(dir, f'{base}_{i}{ext}')):
            i += 1
        return f'{base}_{i}{ext}'
    return file

def setup(container_key_path, client_key_path):
    if not os.path.exists(os.path.expanduser('~/.ssh')):
        subprocess.run(['mkdir', os.path.expanduser('~/.ssh')])
        subprocess.run(['chmod', '700', os.path.expanduser('~/.ssh')])

    if not os.path.exists(os.path.expanduser('~/.ssh/authorized_keys')):
        subprocess.run(['touch', os.path.expanduser('~/.ssh/authorized_keys')])
        subprocess.run(['chmod', '600', os.path.expanduser('~/.ssh/authorized_keys')])

    container_add_count = 0

    # scan the container key
    for root, dirs, files in os.walk(container_key_path):
        for file in files:
            if file.endswith(".pub"):
                with open(os.path.expanduser('~/.ssh/authorized_keys'), 'a') as f:
                    with open(os.path.join(root, file), 'r') as key:
                        f.write(key.read())
                target_file = auto_rename(file, os.path.expanduser('~/.ssh'))
                subprocess.run(['cp', os.path.join(root, file), os.path.expanduser(f'~/.ssh/{target_file}')])
                subprocess.run(['chmod', '644', os.path.expanduser(f'~/.ssh/{target_file}')])
                container_add_count += 1
            else:
                target_file = auto_rename(file, os.path.expanduser('~/.ssh'))
                subprocess.run(['cp', os.path.join(root, file), os.path.expanduser(f'~/.ssh/{target_file}')])
                subprocess.run(['chmod', '600', os.path.expanduser(f'~/.ssh/{target_file}')])

    assert container_add_count > 0, 'Error: no container key found'

    client_add_count = 0

    for root, dirs, files in os.walk(client_key_path):
        for file in files:
            if file.endswith(".pub"):
                with open(os.path.expanduser('~/.ssh/authorized_keys'), 'a') as f:
                    with open(os.path.join(root, file), 'r') as key:
                        f.write(key.read())
                client_add_count += 1
            else:
                print(f'Warning: client key should be a public key, ignoring {file}')

    print(f'Added {container_add_count} container keys and {client_add_count} client keys')

    assert client_add_count > 0, 'Error: no client key found'
    
    # clean up
    clean_count = 0
    with open(os.path.expanduser('~/.ssh/authorized_keys'), 'r') as f:
        authorized_keys = f.readlines()
        clean_count = len(authorized_keys)
        authorized_keys = list(set(authorized_keys))
        clean_count -= len(authorized_keys)
    
    with open(os.path.expanduser('~/.ssh/authorized_keys'), 'w') as f:
        f.writelines(authorized_keys)
    
    print(f'Cleaned {clean_count} duplicate keys in authorized_keys')
        

def init(container_key_path, client_key_path):
    subprocess.run(['mkdir', '-p', client_key_path])
    subprocess.run(['chmod', '700', client_key_path])

    client_key_init_count = 0

    for root, dirs, files in os.walk(os.path.expanduser('~/.ssh')):
        for file in files:
            if file.endswith(".pub"):
                target_file = auto_rename(file, client_key_path)
                subprocess.run(['cp', os.path.join(root, file), os.path.join(client_key_path, target_file)])
                subprocess.run(['chmod', '644', os.path.join(client_key_path, target_file)])
                client_key_init_count += 1
    
    if os.path.exists(os.path.expanduser('~/.ssh/authorized_keys')):
        with open(os.path.expanduser('~/.ssh/authorized_keys'), 'r') as f:
            authorized_keys = f.readlines()
            for index, key in enumerate(authorized_keys):
                if key.strip() == '':
                    continue
                with open(os.path.join(client_key_path, f'authorized_keys_{index}.pub'), 'w') as f:
                    f.write(key)
                client_key_init_count += 1

    print(f'Initialized {client_key_init_count} client keys')
    
    if not os.path.exists(container_key_path) or len(os.listdir(container_key_path)) == 0:
        print(f'Info: container key path {container_key_path} does not exist, generating new keys')
        subprocess.run(['mkdir', '-p', container_key_path])
        subprocess.run(['ssh-keygen', '-t', 'rsa', '-b', '4096', '-f', os.path.join(container_key_path, 'id_rsa'), '-N', ''])

def clean(client_key_path):
    if os.path.exists(client_key_path):
        subprocess.run(['rm', '-rf', os.path.join(client_key_path, "*")])

def main():
    parser = argparse.ArgumentParser(description='Setup SSH environment')
    parser.add_argument('--container_key', type=str, default='container_key', help='Container key')
    parser.add_argument('--client_key', type=str, default='client_key', help='Client key')
    parser.add_argument('--init', action='store_true', help='Copy keys in current machine to ./client_key')
    parser.add_argument('--clean', action='store_true', help='Clean ./client_key')
    parser.add_argument('--install',type=str, default='', help='Docker container to install ssh keys')

    args = parser.parse_args()

    root = os.path.abspath(os.path.dirname(__file__))
    container_key_path = os.path.join(root, args.container_key)
    client_key_path = os.path.join(root, args.client_key)

    if args.init:
        init(container_key_path, client_key_path)
        return

    if args.clean:
        clean(client_key_path)
        return
    
    if args.install:
        dir_path = os.path.dirname(os.path.realpath(__file__))
        subprocess.run(['docker', 'cp', dir_path, f'{args.install}:/tmp/ssh_setup'])
        subprocess.run(['docker', 'exec', args.install, 'python3', '/tmp/ssh_setup/ssh_setup.py'])
        subprocess.run(['docker', 'exec', args.install, 'rm', '-rf', '/tmp/ssh_setup'])
        return 
    
    setup(container_key_path, client_key_path)

if __name__ == '__main__':
    main()
