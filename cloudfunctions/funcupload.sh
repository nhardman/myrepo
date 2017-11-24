#!/bin/bash
bx wsk action update devrequest devrequest.py --kind python:3 --web raw
bx wsk action update github_login github_login.py --kind python:3 --web raw
