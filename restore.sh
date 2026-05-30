#!/bin/bash

# Navega para a pasta de configurações
cd /home/klipper/printer_data/config

# Força o Git a descarregar a versão mais recente do seu repositório privado
git fetch origin
git reset --hard origin/main

# Dá a autorização de execução necessária aos ficheiros de sistema
chmod +x /home/klipper/printer_data/config/*.sh

