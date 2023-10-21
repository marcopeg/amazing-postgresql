#!/bin/bash

# Set public ports:
gh codespace ports visibility 8080:public -c ${CODESPACE_NAME}

# Run the project:
make start