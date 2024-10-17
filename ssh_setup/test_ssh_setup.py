from .ssh_setup import auto_rename, setup
import pytest
import subprocess
import os

@pytest.fixture
def test_env():
    subprocess.run(['rm', '-rf', 'test'])
    yield
    subprocess.run(['rm', '-rf', 'test'])

def test_auto_rename(test_env):
    subprocess.run(['mkdir', '-p', 'test/src'])
    subprocess.run(['mkdir', '-p', 'test/dst'])
    subprocess.run(['touch', 'test/dst/test_1.txt'])
    assert auto_rename('test.txt', 'test/dst') == 'test.txt'
    subprocess.run(['touch', 'test/dst/test.txt'])
    assert auto_rename('test.txt', 'test/dst') == 'test_2.txt'